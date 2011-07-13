#!/usr/bin/env ruby

require 'rubygems'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'jimson'

class TestHandler
  def subtract(a, b)
    a - b
  end
end

server = Jimson::Server.new(TestHandler.new)
server.start
