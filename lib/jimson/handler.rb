module Jimson
  module Handler
    
    def jimson_default_methods
      self.instance_methods.map(&:to_s) - Object.methods.map(&:to_s)
    end

    def jimson_expose(*methods)
      @jimson_exposed_methods ||= []
      @jimson_exposed_methods += methods.map(&:to_s)
    end

    def jimson_exclude(*methods)
      @jimson_excluded_methods ||= []
      @jimson_excluded_methods += methods.map(&:to_s)
    end

    def jimson_exposed_methods
      @jimson_exposed_methods ||= []
      @jimson_excluded_methods ||= []
      (jimson_default_methods - @jimson_excluded_methods + @jimson_exposed_methods).sort
    end

  end
end
