module Sunspot
  module DataExtractor
    class AttributeExtractor
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def value_for(model)
        model.send(@attribute_name)
      end
    end

    class VirtualExtractor
      def initialize(&block)
        @block = block
      end

      def value_for(model)
        Util.instance_eval_or_call(model, &@block)
      end
    end
  end
end
