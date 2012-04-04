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
        @routes[ns.to_s] = handler 
      end

      #
      # Return the handler for a (possibly namespaced) method name
      #
      def handler_for_method(method)
        ns = (method.index('.') == nil ? '' : method.split('.').first)
        @routes[ns]
      end

      #
      # Strip off the namespace part of a method and return the bare method name
      #
      def strip_method_namespace(method)
        # Currently doesn't support nested namespaces, so just return the last part
        method.split('.').last
      end

      #
      # Return an array of all methods on handlers in the map, fully namespaced
      #
      def jimson_methods
        arr = @routes.keys.map do |ns|
          prefix = (ns == '' ? '' : "#{ns}.")
          @routes[ns].class.jimson_exposed_methods.map { |method| prefix + method }
        end
        arr.flatten
      end

    end
  end
end
