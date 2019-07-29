module Sunspot
  # 
  # DataExtractors present an internal API for the indexer to use to extract
  # field values from models for indexing. They must implement the #value_for
  # method, which takes an object and returns the value extracted from it.
  #
  module DataExtractor #:nodoc: all
    #
    # Abstract extractor to perform common actions on extracted values
    #
    class AbstractExtractor
      BLACKLIST_REGEXP = /[\x0-\x8\xB\xC\xE-\x1F\x7f\uFFFE-\uFFFF]/

      def value_for(object)
        extract_value_from(object)
      end

      private

      def extract_value_from(object)
        case object
          when String
            remove_blacklisted_chars(object)
          when Array
            object.map { |o| extract_value_from(o) }
          when Hash
            object.inject({}) { |h, (k, v)| h.merge(extract_value_from(k) => extract_value_from(v)) }
          else
            object
        end
      end

      def remove_blacklisted_chars(object)
        object.gsub(BLACKLIST_REGEXP, '')
      end
    end

    # 
    # AttributeExtractors extract data by simply calling a method on the block.
    #
    class AttributeExtractor < AbstractExtractor
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def value_for(object)
        super object.send(@attribute_name)
      end
    end

    # 
    # BlockExtractors extract data by evaluating a block in the context of the
    # object instance, or if the block takes an argument, by passing the object
    # as the argument to the block. Either way, the return value of the block is
    # the value returned by the extractor.
    #
    class BlockExtractor < AbstractExtractor
      def initialize(&block)
        @block = block
      end

      def value_for(object)
        super Util.instance_eval_or_call(object, &@block)
      end
    end

    # 
    # Constant data extractors simply return the same value for every object.
    #
    class Constant < AbstractExtractor
      def initialize(value)
        @value = value
      end

      def value_for(object)
        super @value
      end
    end
  end
end
