#!/usr/bin/env ruby

require 'jimson'

class MyHandler
  extend Jimson::Handler

  def sum(a, b)
    a + b
  end
end

server = Jimson::Server.new(MyHandler.new)
server.start # serve with webrick on http://0.0.0.0:8999/
