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
        handler = handler.new if handler.is_a?(Class)
        @routes[''] = handler
      end

      #
      # Define the handler for a namespace
      #
      def namespace(ns, handler = nil, &block)
        if !!handler
          handler = handler.new if handler.is_a?(Class)
          @routes[ns.to_s] = handler
        else
          # passed a block for nested namespacing
          map = Jimson::Router::Map.new
          @routes[ns.to_s] = map
          map.instance_eval &block
        end
      end

      #
      # Return the handler for a (possibly namespaced) method name
      #
      def handler_for_method(method)
        parts = method.split('.')
        ns = (method.index('.') == nil ? '' : parts.first)
        handler = @routes[ns]
        if handler.is_a?(Jimson::Router::Map)
          return handler.handler_for_method(parts[1..-1].join('.'))
        end
        handler
      end

      #
      # Strip off the namespace part of a method and return the bare method name
      #
      def strip_method_namespace(method)
        method.split('.').last
      end

      #
      # Return an array of all methods on handlers in the map, fully namespaced
      #
      def jimson_methods
        arr = @routes.keys.map do |ns|
          prefix = (ns == '' ? '' : "#{ns}.")
          handler = @routes[ns]
          if handler.is_a?(Jimson::Router::Map)
            handler.jimson_methods
          else
            handler.class.jimson_exposed_methods.map { |method| prefix + method }
          end
        end
        arr.flatten
      end

    end
  end
end
