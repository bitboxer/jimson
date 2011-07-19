module Jimson
  class Request

    attr_accessor :method, :params, :id
    def initialize(method, params, id = nil)
      @method = method
      @params = params
      @id = id
    end

    def to_h
      h = {
        'jsonrpc' => '2.0',
        'method'  => @method
      }
      h.merge!('params' => @params) if !!@params && !params.empty?
      h.merge!('id' => id)
    end

    def to_json(s)
      self.to_h.to_json
    end

  end
end
