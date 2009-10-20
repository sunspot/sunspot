module Sunspot
  module Rails
    module Spec
      module Extension
        def self.included(base)
          base.class_eval do
            class_inheritable_accessor :sunspot_integration
            extend  ClassMethods
          end
        end
        
        def integrate_sunspot?
          self.class.integrate_sunspot?
        end
        
        def mock_sunspot
          [ :index, :remove_from_index ].each do |method_name|
            Sunspot.stub!(method_name)
          end
        end
        
      end
      
      module ClassMethods
        def integrate_sunspot( integrate = true )
          self.sunspot_integration = integrate
        end

        def integrate_sunspot?
          !!self.sunspot_integration
        end
      end
    end
  end
end

module ActiveSupport
  class TestCase
    before(:each) do
      mock_sunspot unless integrate_sunspot?
    end
    
    include Sunspot::Rails::Spec::Extension
  end
end
