require 'eventmachine'
require 'evma_httpserver'
require 'logger'
require 'json'

module Jimson
  class HttpServer < EM::Connection
    include EM::HttpServer

    def self.handler=(handler)
      @@handler = handler
    end

    def process_http_request
      req = parse_request(@http_post_content)

      resp = EM::DelegatedHttpResponse.new( self )
      resp.status = 200
      resp.content = create_response(req)
      resp.send_response
    end

    def create_response(request)
      params = request['params']
      if params.is_a?(Hash)
        result = @@handler.send(request['method'], params)
      else
        result = @@handler.send(request['method'], *params)
      end

      # A Notification is a Request object without an "id" member.
      # The Server MUST NOT reply to a Notification, including those 
      # that are within a batch request.
      return nil if !request.has_key?('id')

      resp = {
               'jsonrpc' => JSON_RPC_VERSION,
               'result'  => result,  
               'id'      => request['id']
             }.to_json
    end

    def parse_request(post)
      data = JSON.parse(post)
    end

  end

  class Server
    
    attr_accessor :handler, :host, :port, :logger

    def initialize(handler, host = '0.0.0.0', port = 8999, logger = Logger.new(STDOUT))
      @handler = handler
      @host = host
      @port = port
      @logger = logger
    end

    def start
      Jimson::HttpServer.handler = @handler
      EM.run do
        EM::start_server(@host, @port, Jimson::HttpServer)
        @logger.info("Server listening on #{@host}:#{@port} with handler '#{@handler}'")
      end
    end

  end
end
