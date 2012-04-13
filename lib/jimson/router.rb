require 'jimson/router/map'
require 'forwardable'

module Jimson
  class Router
    extend Forwardable

    def_delegators :@map, :handler_for_method,
                          :root,
                          :namespace,
                          :jimson_methods,
                          :strip_method_namespace

    def initialize
      @map = Map.new
    end

    def draw(&block)
      @map.instance_eval &block
      self
    end

  end
end
