module Jimson
  module ClientError
    class InvalidResponse < Exception
      def initialize(msg = nil)
        super(msg || 'Invalid or empty response from server.')
      end
    end
  end
end
