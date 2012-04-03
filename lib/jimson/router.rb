require 'jimson/router/map'

module Jimson
  class Router
    extend Forwardable

    def_delegator :@map, :handler_for_method

    def initialize
      @map = Map.new
    end

    def draw(&block)
      @map.instance_eval(&block)
    end

  end
end
