#!/usr/bin/env ruby

require 'jimson'

client = Jimson::Client.new('http://0.0.0.0:8999/') # the URL for the JSON-RPC 2.0 server to connect to
result = client.sum(1, 2) # call the 'sum' method on the RPC server and save the result '3'

puts result
