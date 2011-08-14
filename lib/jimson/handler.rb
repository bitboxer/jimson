module Jimson
  module Handler
    
    def jimson_default_methods
      self.instance_methods - Object.methods
    end

    def jimson_expose(*methods)
      @jimson_exposed_methods ||= jimson_default_methods 
      @jimson_exposed_methods.merge!(methods)
    end

    def jimson_exclude(*methods)
      @jimson_exposed_methods ||= jimson_default_methods 
      @jimson_exposed_methods -= methods
    end

    def jimson_exposed_methods
      @jimson_exposed_methods ||= jimson_default_methods
      @jimson_exposed_methods
    end

  end
end
