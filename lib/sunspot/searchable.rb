module Sunspot
  module Searchable
    def self.included(base)
      base.send :extend, ActivationMethods 
    end

    module ActivationMethods
      def is_searchable(&block)
        unless self.kind_of? ClassMethods
          extend ClassMethods
          include InstanceMethods
        end
        configure_search(&block)
      end
    end

    module ClassMethods
      def configure_search(&block)
        ::Sunspot::FieldBuilder.new(self).instance_eval(&block) if block
      end
    end

    module InstanceMethods

    end
  end
end
