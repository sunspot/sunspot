module Sunspot
  module Restriction #:nodoc:
    class <<self
      #
      # Return the names of all of the restriction classes that should be made
      # available to the DSL.
      #
      # ==== Returns
      # 
      # Array:: Collection of restriction class names
      #
      def names
        constants - %w(Base SameAs) #XXX this seems ugly
      end
    end

    # 
    # Subclasses of this class represent restrictions that can be applied to
    # a Sunspot query. The Sunspot::DSL::Restriction class presents a builder
    # API for instances of this class.
    #
    # Implementations of this class must respond to #to_params and
    # #to_negative_params. Instead of implementing those methods, they may
    # choose to implement any of:
    #
    # * #to_positive_boolean_phrase, and optionally #to_negative_boolean_phrase
    # * #to_solr_conditional
    #
    class Base #:nodoc:
      def initialize(field, value, negative = false)
        @field, @value, @negative = field, value, negative
      end

      # 
      # A hash representing this restriction in solr-ruby's parameter format.
      # All restriction implementations must respond to this method; however,
      # the base implementation delegates to the #to_positive_boolean_phrase method, so
      # subclasses may (and probably should) choose to implement that method
      # instead.
      #
      # ==== Returns
      #
      # Hash:: Representation of this restriction as solr-ruby parameters
      #
      def to_params
        { :filter_queries => [to_boolean_phrase] }
      end

      # 
      # Return the boolean phrase associated with this restriction object.
      # Differentiates between positive and negative boolean phrases depending
      # on whether this restriction is negated.
      #
      def to_boolean_phrase
        unless negative?
          to_positive_boolean_phrase
        else
          to_negative_boolean_phrase
        end
      end

      # 
      # Boolean phrase representing this restriction in the positive. Subclasses
      # may choose to implement this method rather than #to_params; however,
      # this method delegates to the abstract #to_solr_conditional method, which
      # in most cases will be what subclasses will want to implement.
      # #to_solr_conditional contains the boolean phrase representing the
      # condition but leaves out the field name (see built-in implementations
      # for examples)
      #
      # ==== Returns
      #
      # String:: Boolean phrase for restriction in the positive
      #
      def to_positive_boolean_phrase
        "#{@field.indexed_name}:#{to_solr_conditional}"
      end

      # 
      # Boolean phrase representing this restriction in the negative. Subclasses
      # may choose to implement this method, but it is not necessary, as the
      # base implementation delegates to #to_positive_boolean_phrase.
      #
      # ==== Returns
      #
      # String:: Boolean phrase for restriction in the negative
      #
      def to_negative_boolean_phrase
        "-#{to_positive_boolean_phrase}"
      end

      protected

      # 
      # Whether this restriction should be negated from its original meaning
      #
      def negative?
        !!@negative
      end

      # 
      # Return escaped Solr API representation of given value
      #
      # ==== Parameters
      #
      # value<Object>::
      #   value to convert to Solr representation (default: @value)
      #
      # ==== Returns
      #
      # String:: Solr API representation of given value
      #
      def solr_value(value = @value)
        Solr::Util.query_parser_escape(@field.to_indexed(value))
      end
    end

    # 
    # Results must have field with value equal to given value
    #
    class EqualTo < Base
      private

      def to_solr_conditional
        "#{solr_value}"
      end
    end

    # 
    # Results must have field with value less than given value
    #
    class LessThan < Base
      private

      def to_solr_conditional
        "[* TO #{solr_value}]"
      end
    end

    # 
    # Results must have field with value greater than given value
    #
    class GreaterThan < Base
      private

      def to_solr_conditional
        "[#{solr_value} TO *]"
      end
    end

    # 
    # Results must have field with value in given range
    #
    class Between < Base
      private

      def to_solr_conditional
        "[#{solr_value(@value.first)} TO #{solr_value(@value.last)}]"
      end
    end

    # 
    # Results must have field with value included in given collection
    #
    class AnyOf < Base
      private

      def to_solr_conditional
        "(#{@value.map { |v| solr_value v } * ' OR '})"
      end
    end

    #
    # Results must have field with values matching all values in given
    # collection (only makes sense for fields with multiple values)
    #
    class AllOf < Base
      private

      def to_solr_conditional
        "(#{@value.map { |v| solr_value v } * ' AND '})"
      end
    end

    # 
    # Result must be the exact instance given (only useful when negated).
    #
    class SameAs < Base
      def initialize(object, negative = false)
        @object, @negative = object, negative
      end

      def to_positive_boolean_phrase
        adapter = Adapters::InstanceAdapter.adapt(@object)
        "id:#{Solr::Util.query_parser_escape(adapter.index_id)}"
      end
    end
  end
end
