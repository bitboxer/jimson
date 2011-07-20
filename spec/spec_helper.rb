require 'rubygems'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'jimson/server'
require 'jimson/client'
require 'open-uri'
require 'json'

SPEC_URL = 'http://localhost:8999'

pid = Process.spawn(File.dirname(__FILE__) + '/em_helper.rb')

RSpec.configure do |config|
  config.after(:all) do
    Process.kill(9, pid)
  end
end

sleep 1

