module Jimson
  module ClientError
    class Generic < Exception
    end

    class InvalidResponse < Generic 
      def initialize()
        super('Invalid or empty response from server.')
      end
    end

    class InvalidJSON <  Generic
      def initialize(json)
        super("Couldn't parse JSON string received from server:\n#{json}")
      end
    end

    class InternalError < Generic
      def initialize(e)
        super("An internal client error occurred when processing the request: #{e}\n#{e.backtrace.join("\n")}")
      end
    end

    class UnknownServerError < Generic 
      def initialize(code, message)
        super("The server specified an error the client doesn't know about: #{code} #{message}")
      end
    end

  end
end
