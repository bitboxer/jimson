# Jimson (It's a fork with plans to become separate project in near future)

### JSON-RPC 2.0 Client and Server for Ruby
![next build status](https://secure.travis-ci.org/mitfik/jimson.png?branch=next)

## Client: Quick Start
    require 'jimson'
    client = Jimson::Client.new("http://www.example.com:8999") # the URL for the JSON-RPC 2.0 server to connect to
    result = client.sum(1,2) # call the 'sum' method on the RPC server and save the result '3'

## Server: Quick Start
    require 'jimson'

    class MyHandler
      extend Jimson::Handler

      def sum(a,b)
        a + b
      end
    end

    server = Jimson::Server.new(MyHandler.new)
    server.start # serve with webrick on http://0.0.0.0:8999/

## JSON Engine
Jimson uses multi\_json, so you can load the JSON library of your choice in your application and Jimson will use it automatically.

For example, require the 'json' gem in your application:
    require 'json'


## Roadmap

* Compatitbility with latest jruby, ruby 1.9 and ruby 2.1
* Divide it into client and server (separate gems)
* keep compatibility only with JSON-RPC 2.0

