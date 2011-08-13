require 'rest-client'
require 'jimson/server_error'
require 'jimson/client_error'
require 'jimson/request'
require 'jimson/response'

module Jimson
  class ClientHelper
    JSON_RPC_VERSION = '2.0'

    def self.make_id
      rand(10**12)
    end

    def initialize(url)
      @url = url
      URI.parse(@url) # for the sake of validating the url
      @batch = []
    end

    def process_call(sym, args)
      resp = send_single_request(sym.to_s, args)

      data = JSON.parse(resp) rescue raise Client::Error::InvalidJSON.new(resp)

      return process_single_response(data)

      rescue Exception, StandardError => e
        e.extend(Client::Error) unless e.is_a?(Client::Error)
        raise e
    end

    def send_single_request(method, args)
      post_data = {
                    'jsonrpc' => JSON_RPC_VERSION,
                    'method'  => method,
                    'params'  => args,
                    'id'      => self.class.make_id
                  }.to_json
      resp = RestClient.post(@url, post_data, :content_type => 'application/json')
      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise Client::Error::InvalidResponse.new
      end

      return resp.body
    end

    def send_batch_request(batch)
      post_data = batch.to_json
      resp = RestClient.post(@url, post_data, :content_type => 'application/json')
      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise Client::Error::InvalidResponse.new
      end

      return resp.body
    end

    def process_batch_response(responses)
      responses.each do |resp|
        saved_response = @batch.map { |r| r[1] }.select { |r| r.id == resp['id'] }.first
        raise Client::Error::InvalidResponse.new if saved_response.nil?
        saved_response.populate!(resp)
      end
    end

    def process_single_response(data)
      raise Client::Error::InvalidResponse.new if !valid_response?(data)

      if !!data['error']
        code = data['error']['code']
        msg = data['error']['message']
        raise Client::Error::ServerError.new(code, msg)
      end

      return data['result']
    end

    def valid_response?(data)
      return false if !data.is_a?(Hash)

      return false if data['jsonrpc'] != JSON_RPC_VERSION

      return false if !data.has_key?('id')

      return false if data.has_key?('error') && data.has_key?('result')

      if data.has_key?('error')
        if !data['error'].is_a?(Hash) || !data['error'].has_key?('code') || !data['error'].has_key?('message') 
          return false
        end

        if !data['error']['code'].is_a?(Fixnum) || !data['error']['message'].is_a?(String)
          return false
        end
      end

      return true
      
      rescue
        return false
    end

    def push_batch_request(request)
      request.id = self.class.make_id
      response = Response.new(request.id)
      @batch << [request, response]
      return response
    end

    def send_batch
      batch = @batch.map(&:first) # get the requests 
      response = send_batch_request(batch)

      responses = JSON.parse(response) rescue raise Client::Error::InvalidJSON.new(json)

      process_batch_response(responses)
      @batch = []
    end

  end

  class BatchClient
    
    def initialize(helper)
      @helper = helper
    end

    def method_missing(sym, *args, &block)
      request = Jimson::Request.new(sym.to_s, args)
      @helper.push_batch_request(request) 
    end

  end

  class Client
    
    def self.batch(client)
      helper = client.instance_variable_get(:@helper)
      batch_client = BatchClient.new(helper)
      yield batch_client
      helper.send_batch
    end

    def initialize(url)
      @helper = ClientHelper.new(url)
    end

    def method_missing(sym, *args, &block)
      @helper.process_call(sym, args) 
    end

  end
end
