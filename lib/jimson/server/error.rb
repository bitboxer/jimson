module Jimson
  class Server
    class Error < StandardError
      attr_accessor :code, :message

      def initialize(code, message)
        @code = code
        @message = message
        super(message)
      end

      def to_h
        {
          'code'    => @code,
          'message' => @message
        }
      end

      class ParseError < Error
        def initialize
          super(-32700, 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.')
        end
      end

      class InvalidRequest < Error
        def initialize
          super(-32600, 'The JSON sent is not a valid Request object.')
        end
      end

      class MethodNotFound < Error
        def initialize(method)
          super(-32601, "Method '#{method}' not found.")
        end
      end

      class InvalidParams < Error
        def initialize
          super(-32602, 'Invalid method parameter(s).')
        end
      end

      class InternalError < Error
        def initialize(e)
          super(-32603, "Internal server error: #{e}")
        end
      end

      class ApplicationError < Error
        def initialize(err, show_error = false)
          msg = "Server application error"
          msg += ': ' + err.message + ' at ' + err.backtrace.first if show_error
          super(-32099, msg)
        end
      end

      CODES = {
                -32700 => ParseError,
                -32600 => InvalidRequest,
                -32601 => MethodNotFound,
                -32602 => InvalidParams,
                -32603 => InternalError
              }
    end
  end
end
