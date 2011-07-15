require 'patron'

module Jimson
  class ClientHelper

    def self.make_id
      rand(10**12)
    end

    def initialize(url)
      @http = Patron::Session.new
      uri = URI(url)
      @path = uri.path
      @http.base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end

    def process_call(sym, args)
      post_data = {
                    'jsonrpc' => '2.0',
                    'method'  => sym.to_s,
                    'params'  => args,
                    'id'      => self.class.make_id
                  }.to_json
      @http.post(@path, post_data)
    end

  end

  class Client

    def initialize(url)
      @helper = ClientHelper.new(url)
    end

    def method_missing(sym, *args, &block)
      @helper.process_call(sym, args) 
    end

  end
end
