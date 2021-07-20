# Jimson

### [JSON-RPC 2.0](https://www.jsonrpc.org/specification) Client and Server for Ruby

[![Build Status](https://github.com/chriskite/jimson/actions/workflows/ruby.yml/badge.svg?branch=main)](https://github.com/chriskite/jimson/actions/workflows/ruby.yml)

## Client: Quick Start

```ruby
require 'jimson'
client = Jimson::Client.new("http://www.example.com:8999") # the URL for the JSON-RPC 2.0 server to connect to
result = client.sum(1,2) # call the 'sum' method on the RPC server and save the result '3'
```

## Server: Quick Start

```ruby
require 'jimson'

class MyHandler
  extend Jimson::Handler

  def sum(a,b)
    a + b
  end
end

server = Jimson::Server.new(MyHandler.new)
server.start # serve with webrick on http://0.0.0.0:8999/
```

## JSON Engine

Jimson uses [multi\_json](https://github.com/intridea/multi_json), so you can load the JSON library of your choice in your application and Jimson will use it automatically.

For example, require the 'json' gem in your application:

```ruby
require 'json'
```

## Previous maintainer

This gem was maintained by [Chris Kite](https://github.com/chriskite/) till April 2021.
