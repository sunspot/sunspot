module Sunspot
  # 
  # DataExtractors present an internal API for the indexer to use to extract
  # field values from models for indexing. They must implement the #value_for
  # method, which takes an object and returns the value extracted from it.
  #
  module DataExtractor #:nodoc: all
    # 
    # AttributeExtractors extract data by simply calling a method on the block.
    #
    class AttributeExtractor
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def value_for(object)
        object.send(@attribute_name)
      end
    end

    # 
    # BlockExtractors extract data by evaluating a block in the context of the
    # object instance, or if the block takes an argument, by passing the object
    # as the argument to the block. Either way, the return value of the block is
    # the value returned by the extractor.
    #
    class BlockExtractor
      def initialize(&block)
        @block = block
      end

      def value_for(object)
        Util.instance_eval_or_call(object, &@block)
      end
    end

    # 
    # Constant data extractors simply return the same value for every object.
    #
    class Constant
      def initialize(value)
        @value = value
      end

      def value_for(object)
        @value
      end
    end
  end
end
