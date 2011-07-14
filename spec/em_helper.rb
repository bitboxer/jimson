#!/usr/bin/env ruby

require 'rubygems'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'jimson'

class TestHandler
  def n_subtract(args)
    a, b = args['subtrahend'], args['minuend']
    subtract(a,b)
  end

  def subtract(a, b)
    a - b
  end
end

server = Jimson::Server.new(TestHandler.new)
server.start
