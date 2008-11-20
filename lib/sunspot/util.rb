module Sunspot
  module Util
    class ClosedStruct
      def initialize(data)
        (class <<self; self; end).module_eval do
          data.each_pair do |attr_name, value|
            define_method(attr_name.to_s) { value }
          end
        end
      end
    end
  end
end
