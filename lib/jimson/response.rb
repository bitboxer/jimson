module Jimson
  class Response
    attr_accessor :result, :error, :id

    def initialize(id)
      @id = id
    end

    def to_h
      h = {'jsonrpc' => '2.0'}
      h.merge!('result' => @result) if !!@result
      h.merge!('error' => @error) if !!@error
      h.merge!('id' => @id)
    end

    def is_error?
      !!@error
    end

    def succeeded?
      !!@result
    end

    def populate!(data)
      @error = data['error'] if !!data['error']
      @result = data['result'] if !!data['result']
    end

  end
end
