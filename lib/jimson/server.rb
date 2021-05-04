require 'rack'
require 'rack/request'
require 'rack/response'
require 'multi_json'
require 'jimson/handler'
require 'jimson/router'
require 'jimson/server/error'

module Jimson
  class Server
    
    class System
      extend Handler

      def initialize(router)
        @router = router
      end

      def listMethods
        @router.jimson_methods
      end

      def isAlive 
        true
      end
    end

    JSON_RPC_VERSION = '2.0'

    attr_accessor :router, :host, :port, :show_errors, :opts

    #
    # Create a Server with routes defined
    #
    def self.with_routes(opts = {}, &block)
      router = Router.new
      router.send(:draw, &block)
      self.new(router, opts)
    end

    #
    # +router_or_handler+ is an instance of Jimson::Router or extends Jimson::Handler
    #
    # +opts+ may include:
    # * :host - the hostname or ip to bind to
    # * :port - the port to listen on
    # * :server - the rack handler to use, e.g. 'webrick' or 'thin'
    # * :show_errors - true or false, send backtraces in error responses?
    #
    # Remaining options are forwarded to the underlying Rack server.
    #
    def initialize(router_or_handler, opts = {})
      if !router_or_handler.is_a?(Router)
        # arg is a handler, wrap it in a Router
        @router = Router.new
        @router.root router_or_handler
      else
        # arg is a router
        @router = router_or_handler
      end
      @router.namespace 'system', System.new(@router)

      @host = opts.delete(:host) || '0.0.0.0'
      @port = opts.delete(:port) || 8999
      @show_errors = opts.delete(:show_errors) || false 
      @opts = opts
    end

    #
    # Starts the server so it can process requests
    #
    def start
      Rack::Server.start(opts.merge(
        :app    => self,
        :Host   => @host,
        :Port   => @port
      ))
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

      MultiJson.encode(response)
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
                         'id'      => [String, Integer, NilClass]
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
      method = request['method']
      params = request['params']
      result = dispatch_request(method, params)

      response = success_response(request, result)

      # A Notification is a Request object without an "id" member.
      # The Server MUST NOT reply to a Notification, including those 
      # that are within a batch request.
      response = nil if !request.has_key?('id')

      return response 

      rescue Server::Error => e
        raise e
      rescue ArgumentError
        raise Server::Error::InvalidParams.new
      rescue Exception, StandardError => e
        raise Server::Error::ApplicationError.new(e, @show_errors)
    end

    def dispatch_request(method, params)
      method_name = method.to_s
      handler = @router.handler_for_method(method_name)
      method_name = @router.strip_method_namespace(method_name)

      if handler.nil? \
      || !handler.class.jimson_exposed_methods.include?(method_name) \
      || !handler.respond_to?(method_name)
        raise Server::Error::MethodNotFound.new(method)
      end

      if params.nil?
        return handler.send(method_name)
      elsif params.is_a?(Hash)
        return handler.send(method_name, params)
      else
        return handler.send(method_name, *params)
      end
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
      data = MultiJson.decode(post)
      rescue 
        raise Server::Error::ParseError.new 
    end

  end
end
