module Sunspot
  module Query
    module ExternalFileRestriction #:nodoc:

      class Base < Sunspot::Query::Restriction::Base
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
          "#{to_solr_conditional}#{Util.escape(@field.indexed_name)}"
        end

        #
        # Boolean phrase representing this restriction in the negated. Subclasses
        # may choose to implement this method, but it is not necessary, as the
        # base implementation delegates to #to_positive_boolean_phrase.
        #
        # ==== Returns
        #
        # String:: Boolean phrase for restriction in the negated
        #
        def to_negated_boolean_phrase
          "-#{to_positive_boolean_phrase}"
        end

        def solr_value(value = @value)
          @field.to_indexed(value)
        end
      end

      #
      # Results must have field with value equal to given value. If the value
      # is nil, results must have no value for the given field.
      #
      class EqualTo < Base
        private

        def to_solr_conditional
          "{!frange l=#{solr_value} u=#{solr_value}}"
        end
      end

      #
      # Results must have field with value less than given value
      #
      class LessThan < Base
        private

        def to_solr_conditional
          "{!frange u=#{solr_value} incu=false}"
        end
      end

      #
      # Results must have field with value less or equal to than given value
      #
      class LessThanOrEqualTo < Base
        private

        def to_solr_conditional
          "{!frange u=#{solr_value} incu=true}"
        end
      end

      #
      # Results must have field with value greater than given value
      #
      class GreaterThan < Base
        private

        def to_solr_conditional
          "{!frange l=#{solr_value} incl=false}"
        end
      end

      #
      # Results must have field with value greater than or equal to given value
      #
      class GreaterThanOrEqualTo < Base
        private

        def to_solr_conditional
          "{!frange l=#{solr_value} incl=true}"
        end
      end

      #
      # Results must have field with value in given range
      #
      class Between < Base
        private

        def to_solr_conditional
          "{!frange l=#{solr_value.first} u=#{solr_value.last} incl=true incu=true}"
        end

        def solr_value(value = @value)
          [@field.to_indexed(value.first), @field.to_indexed(value.last)]
        end
      end

    end
  end
end
