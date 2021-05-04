# Jimson-Reloaded

This is a fork of [chriskite/jimson](https://github.com/chriskite/jimson). I merged all open PRs of the original unmaintaned gem and will maintain it as `jimson-reloaded`. PRs are welcome 🤗.

### JSON-RPC 2.0 Client and Server for Ruby

[![Build Status](https://travis-ci.org/chriskite/jimson.svg?branch=master)](https://travis-ci.org/chriskite/jimson)

## Client: Quick Start

```ruby
require 'jimson-reloaded'
client = Jimson::Client.new("http://www.example.com:8999") # the URL for the JSON-RPC 2.0 server to connect to
result = client.sum(1,2) # call the 'sum' method on the RPC server and save the result '3'
```

## Server: Quick Start

```ruby
require 'jimson-reloaded'

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

Jimson uses multi\_json, so you can load the JSON library of your choice in your application and Jimson will use it automatically.

For example, require the 'json' gem in your application:

```ruby
require 'json'
```

