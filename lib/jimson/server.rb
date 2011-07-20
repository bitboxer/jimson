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
      resp.content = process_post(@http_post_content)
      resp.send_response
    end

    def process_post(content)
      begin
        request = parse_request(@http_post_content)
        if request.is_a?(Array)
          raise Jimson::ServerError::InvalidRequest.new if request.empty?
          response = request.map { |req| handle_request(req) }
        else
          response = handle_request(request)
        end
      rescue Jimson::ServerError::ParseError, Jimson::ServerError::InvalidRequest => e
        response = error_response(e)
      rescue Jimson::ServerError::Generic => e
        response = error_response(e, request)
      rescue StandardError, Exception
        response = error_response(Jimson::ServerError::InternalError.new)
      end

      response.compact! if response.is_a?(Array)

      return nil if response.nil? || (response.respond_to?(:empty?) && response.empty?)

      response.to_json
    end

    def handle_request(request)
      response = nil
      begin
        if !validate_request(request)
          response = error_response(Jimson::ServerError::InvalidRequest.new)
        else
          response = create_response(request)
        end
      rescue Jimson::ServerError::Generic => e
        response = error_response(e, request)
      end

      response
    end

    def validate_request(request)
      required_keys = %w(jsonrpc method)
      required_types = {
                         'jsonrpc' => [String],
                         'method'  => [String], 
                         'params'  => [Hash, Array],
                         'id'      => [String, Fixnum, NilClass]
                       }
      
      return false if !request.is_a?(Hash)

      required_keys.each do |key|
        return false if !request.has_key?(key)
      end

      required_types.each do |key, types|
        return false if request.has_key?(key) && !types.any? { |type| request[key].is_a?(type) }
      end

      return false if request['jsonrpc'] != '2.0'
      
      true
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
        raise Jimson::ServerError::MethodNotFound.new 
      rescue ArgumentError
        raise Jimson::ServerError::InvalidParams.new
      rescue
        raise Jimson::ServerError::ApplicationError.new($!)
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

      resp
    end

    def success_response(request, result)
      {
        'jsonrpc' => JSON_RPC_VERSION,
        'result'  => result,  
        'id'      => request['id']
      }
    end

    def parse_request(post)
      data = JSON.parse(post)
      rescue 
        raise Jimson::ServerError::ParseError.new 
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
