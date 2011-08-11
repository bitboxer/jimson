#!/usr/bin/env ruby

require 'rubygems'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'jimson'

class TestHandler
  def subtract(a, b = nil)
    if a.is_a?(Hash)
      return a['minuend'] - a['subtrahend']
    else 
      return a - b
    end
  end

  def sum(a,b,c)
    a + b + c
  end

  def notify_hello(*args)
    # notification, doesn't do anything
  end

  def update(*args)
    # notification, doesn't do anything
  end

  def get_data
    ['hello', 5]
  end
end

server = Jimson::Server.new(TestHandler.new)
server.start
