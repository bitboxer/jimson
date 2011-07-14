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
      resp = EM::DelegatedHttpResponse.new( self )
      resp.status = 200

      begin
        request = parse_request(@http_post_content)
        if !validate_request(request)
          raise Jimson::Error::InvalidRequest.new
        end
        resp.content = create_response(request)
      rescue Jimson::Error::ParseError => e
        resp.content = error_response(e)
      rescue Jimson::Error::MethodNotFound => e
        resp.content = error_response(e, request)
      rescue Jimson::Error::InvalidRequest => e
        resp.content = error_response(e, request)
      end

      resp.send_response
    end

    def validate_request(request)
      valid = true 
      required_keys = %w(jsonrpc method)
      required_types = {
                         'jsonrpc' => [String],
                         'method'  => [String], 
                         'params'  => [Hash, Array],
                         'id'      => [String, Fixnum, NilClass]
                       }
      
      required_keys.each do |key|
        valid = false if !request.has_key?(key)
      end

      required_types.each do |key, types|
        valid = false if request.has_key?(key) && !types.any? { |type| request[key].is_a?(type) }
      end

      valid = false if request['jsonrpc'] != '2.0'
      
      valid
    end

    def create_response(request)
      params = request['params']
      begin
        if params.is_a?(Hash)
          result = @@handler.send(request['method'], params)
        else
          result = @@handler.send(request['method'], *params)
        end
      rescue NoMethodError
        raise Jimson::Error::MethodNotFound.new 
      end

      response = success_response(request, result)

      # A Notification is a Request object without an "id" member.
      # The Server MUST NOT reply to a Notification, including those 
      # that are within a batch request.
      response = nil if !request.has_key?('id')

      response 
    end

    def error_response(error, request = nil)
      resp = {
               'jsonrpc' => JSON_RPC_VERSION,
               'error'   => error.to_h,
             }
      if !!request && request.has_key?('id')
        resp['id'] = request['id'] 
      else
        resp['id'] = nil
      end

      resp.to_json
    end

    def success_response(request, result)
      {
        'jsonrpc' => JSON_RPC_VERSION,
        'result'  => result,  
        'id'      => request['id']
      }.to_json
    end

    def parse_request(post)
      data = JSON.parse(post)
      rescue 
        raise Jimson::Error::ParseError.new 
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
