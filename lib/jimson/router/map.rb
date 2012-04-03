module Jimson
  class Router

    #
    # Provides a DSL for routing method namespaces to handlers.
    # Only handles root-level and non-nested namespaces, e.g. 'foo.bar' or 'foo'.
    #
    class Map

      def initialize
        @routes = {}
      end

      #
      # Set the root handler, i.e. the handler used for a bare method like 'foo'
      #
      def root(handler)
        @routes[''] = handler
      end

      #
      # Define the handler for a namespace
      #
      def namespace(ns, handler)
        @routes[ns] = handler 
      end

      #
      # Return the handler for a (possibly namespaced) method name
      #
      def handler_for_method(method)
        ns = (method.index('.') == nil ? '' : method.split('.').first)
        @routes[ns]
      end

    end
  end
end
