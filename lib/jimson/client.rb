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
      resp = send_single_request(sym.to_s, args)

      begin
        data = JSON.parse(resp)
      rescue
        raise Jimson::ClientError::InvalidJSON.new(json)
      end

      return handle_response(data)
    end

    def send_single_request(method, args)
      post_data = {
                    'jsonrpc' => '2.0',
                    'method'  => method,
                    'params'  => args,
                    'id'      => self.class.make_id
                  }.to_json
      resp = @http.post(@path, post_data)
      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise Jimson::ClientError::InvalidResponse.new
      end

      return resp.body

      rescue Exception, StandardError
        raise new Jimson::ClientError::InternalError.new($!)
    end

    def handle_response(data)
      raise Jimson::ClientError::InvalidResponse.new if !valid_response?(data)

      if !!data['error']
        code = data['error']['code']
        if Jimson::ServerError::CODES.keys.include?(code)
          raise Jimson::ServerError::CODES[code].new
        else
          raise Jimson::ClientError::UnknownServerError.new(code, data['error']['message'])
        end
      end

      return data['result']

      rescue Exception, StandardError
        raise new Jimson::ClientError::InternalError.new
    end

    def valid_response?(data)
      return false if !data.is_a?(Hash)

      return false if data['jsonrpc'] != '2.0'

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
