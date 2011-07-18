module Jimson
  module ClientError
    class InvalidResponse < Exception
      def initialize(msg = nil)
        super(msg || 'Invalid or empty response from server.')
      end
    end

    class InvalidJSON < Exception
      def initialize(json, msg = nil)
        super(msg || "Couldn't parse JSON string received from server:\n#{json}")
      end
    end
  end
end
