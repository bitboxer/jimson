require 'rubygems'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'jimson'
require 'open-uri'
require 'json'
require 'patron'
require 'fakeweb'

SPEC_URL = 'http://localhost:8999'


def fake_response(json)
  FakeWeb.register_uri(:post, SPEC_URL, :body => json)
end

pid = Process.spawn(File.dirname(__FILE__) + '/em_helper.rb')

RSpec.configure do |config|
  config.after(:all) do
    Process.kill(9, pid)
  end
end

sleep 1

