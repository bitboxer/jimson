module Jimson
  class Client
    class Error < StandardError
      class InvalidResponse < Error
        def initialize()
          super('Invalid or empty response from server.')
        end
      end

      class InvalidJSON < Error
        def initialize(json)
          super("Couldn't parse JSON string received from server:\n#{json}")
        end
      end

      class ServerError < Error
        def initialize(code, message)
          super("Server error #{code}: #{message}")
        end
      end
    end
  end
end
