module Jimson
  class Error
    TYPES = [
              :parse_error,
              :invalid_request,
              :method_not_found,
              :invalid_params,
              :internal_error
            ]

    CODES = {
              :parse_error      => -32700,
              :invalid_request  => -32600,
              :method_not_found => -32601,
              :invalid_params   => -32602,
              :internal_error   => -32603
            }

    MESSAGES = {
                 :parse_error      => 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
                 :invalid_request  => 'The JSON sent is not a valid Request object.',
                 :method_not_found => 'The method does not exist.',
                 :invalid_params   => 'Invalid method parameter(s).',
                 :internal_error   => 'Internal server error.'
               }

    def initialize(type)
      raise 'Invalid error type' unless TYPES.include?(type)
      @code = CODES[type]
      @message = MESSAGES[type]
    end

    def to_h
      {
        'code'    => @code,
        'message' => @message
      }
    end

  end
end
