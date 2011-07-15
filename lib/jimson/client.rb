require 'net/http'

module Jimson
  class ClientHelper
    def initialize(url)
      @http = Patron::Session.new
      @uri = URI.parse(url)
    end

    def process_call(sym, args)
      post_data = {
                    'jsonrpc' => '2.0',
                    'method'  => sym.to_s,
                    'params'  => args,
                    'id'      => make_id
                  }.to_json
      Net::HTTP.post(@uri, post_data)
    end

    protected

    def make_id
      rand(10**12)
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
