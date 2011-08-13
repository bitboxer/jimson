require 'rack'
require 'rack/request'
require 'rack/response'
require 'json'
require 'jimson/server/error'

module Jimson
  class Server
    
    JSON_RPC_VERSION = '2.0'

    attr_accessor :handler, :host, :port

    #
    # +handler+ is an instance of the class to expose as a JSON-RPC server
    #
    # +opts+ may include:
    # * :host - the hostname or ip to bind to
    # * :port - the port to listen on
    # * :server - the rack handler to use, e.g. 'webrick' or 'thin'
    #
    def initialize(handler, opts = {})
      @handler = handler
      @host = opts[:host] || '0.0.0.0'
      @port = opts[:port] || 8999
      @server = opts[:server] || 'webrick'
    end

    #
    # Starts the server so it can process requests
    #
    def start
      Rack::Server.start(
        :server => @server,
        :app    => self,
        :Host   => @host,
        :Port   => @port
      )
    end

    #
    # Entry point for Rack
    #
    def call(env)
      req = Rack::Request.new(env)
      resp = Rack::Response.new
      return resp.finish if !req.post?
      resp.write process(req.body.read)
      resp.finish
    end

    def process(content)
      begin
        request = parse_request(content)
        if request.is_a?(Array)
          raise Server::Error::InvalidRequest.new if request.empty?
          response = request.map { |req| handle_request(req) }
        else
          response = handle_request(request)
        end
      rescue Server::Error::ParseError, Server::Error::InvalidRequest => e
        response = error_response(e)
      rescue Server::Error => e
        response = error_response(e, request)
      rescue StandardError, Exception => e
        response = error_response(Server::Error::InternalError.new(e))
      end

      response.compact! if response.is_a?(Array)

      return nil if response.nil? || (response.respond_to?(:empty?) && response.empty?)

      response.to_json
    end

    def handle_request(request)
      response = nil
      begin
        if !validate_request(request)
          response = error_response(Server::Error::InvalidRequest.new)
        else
          response = create_response(request)
        end
      rescue Server::Error => e
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

      return false if request['jsonrpc'] != JSON_RPC_VERSION
      
      true
    end

    def create_response(request)
      params = request['params']
      begin
        if params.is_a?(Hash)
          result = @handler.send(request['method'], params)
        else
          result = @handler.send(request['method'], *params)
        end
      rescue NoMethodError
        raise Server::Error::MethodNotFound.new 
      rescue ArgumentError
        raise Server::Error::InvalidParams.new
      rescue
        raise Server::Error::ApplicationError.new($!)
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
        raise Server::Error::ParseError.new 
    end

  end
end
