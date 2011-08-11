require 'rack'
require 'rack/request'
require 'rack/response'
require 'rack/showexceptions'
require 'json'
require 'jimson/http_server'

module Jimson
  class Server
    
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
      @app = Jimson::HttpServer.new(@handler)
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
        :app    => @app,
        :Host   => @host,
        :Port   => @port
      )
    end

  end
end
