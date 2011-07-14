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

  def sum(a,b,c)
    a + b + c
  end

  def notify_hello(a)
    # notification, doesn't do anything
  end

  def update(a,b,c,d,e)
    # notification, doesn't do anything
  end

  def get_data
    ['hello', 5]
  end
end

server = Jimson::Server.new(TestHandler.new)
server.start
