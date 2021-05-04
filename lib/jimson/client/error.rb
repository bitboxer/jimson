module Jimson
  class Client
    module Error
      class InvalidResponse < StandardError
        def initialize(response = nil)
          super("Invalid or empty response from server:\n#{response.inspect}")
        end
      end

      class InvalidJSON < StandardError
        def initialize(json)
          super("Couldn't parse JSON string received from server:\n#{json}")
        end
      end

      class ServerError < StandardError
        def initialize(code, message)
          super("Server error #{code}: #{message}")
        end
      end
    end
  end
end
