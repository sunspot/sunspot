module Sunspot
  module Query
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
          constants - %w(Base) #XXX this seems ugly
        end

        # 
        # Convenience method to access a restriction class by an underscored
        # symbol or string
        #
        def [](restriction_name)
          @types ||= {}
          @types[restriction_name.to_sym] ||= const_get(Sunspot::Util.camel_case(restriction_name.to_s))
        end
      end

      # 
      # Subclasses of this class represent restrictions that can be applied to
      # a Sunspot query. The Sunspot::DSL::Restriction class presents a builder
      # API for instances of this class.
      #
      # Implementations of this class must respond to #to_params and
      # #to_negated_params. Instead of implementing those methods, they may
      # choose to implement any of:
      #
      # * #to_positive_boolean_phrase, and optionally #to_negated_boolean_phrase
      # * #to_solr_conditional
      #
      class Base #:nodoc:
        include Filter
        include RSolr::Char

        RESERVED_WORDS = Set['AND', 'OR', 'NOT']

        def initialize(negated, field, value)
          raise ArgumentError.new("RFCTR") unless [true, false].include?(negated)
          @negated, @field, @value = negated, field, value
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
          { :fq => [to_filter_query] }
        end

        # 
        # Return the boolean phrase associated with this restriction object.
        # Differentiates between positive and negated boolean phrases depending
        # on whether this restriction is negated.
        #
        def to_boolean_phrase
          unless negated?
            to_positive_boolean_phrase
          else
            to_negated_boolean_phrase
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
          "#{escape(@field.indexed_name)}:#{to_solr_conditional}"
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

        # 
        # Whether this restriction should be negated from its original meaning
        #
        def negated? #:nodoc:
          !!@negated
        end

        # 
        # Return a new restriction that is the negated version of this one. It
        # is used by disjunction denormalization.
        #
        def negate
          self.class.new(!@negated, @field, @value)
        end

        protected

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
          solr_value = escape(@field.to_indexed(value))
          if RESERVED_WORDS.include?(solr_value)
            %Q("#{solr_value}")
          else
            solr_value
          end
        end
      end

      class InRadius < Base
        def initialize(negated, field, lat, lon, radius)
          @lat, @lon, @radius = lat, lon, radius
          super negated, field, [lat, lon, radius]
        end

        private
          def to_positive_boolean_phrase
            "_query_:\"{!geofilt sfield=#{@field.indexed_name} pt=#{@lat},#{@lon} d=#{@radius}}\""
          end
      end

      # 
      # Results must have field with value equal to given value. If the value
      # is nil, results must have no value for the given field.
      #
      class EqualTo < Base
        def to_positive_boolean_phrase
          unless @value.nil?
            super
          else
            "#{escape(@field.indexed_name)}:[* TO *]"
          end
        end

        def negated?
          if @value.nil?
            !super
          else
            super
          end
        end

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

        def solr_value(value = @value)
          solr_value = super
          solr_value = "\"#{solr_value}\"" if solr_value.index(' ')
          solr_value
        end

        def to_solr_conditional
          "{* TO #{solr_value}}"
        end
      end

      # 
      # Results must have field with value less or equal to than given value
      #
      class LessThanOrEqualTo < Base
        private

        def solr_value(value = @value)
          solr_value = super
          solr_value = "\"#{solr_value}\"" if solr_value.index(' ')
          solr_value
        end

        def to_solr_conditional
          "[* TO #{solr_value}]"
        end
      end

      # 
      # Results must have field with value greater than given value
      #
      class GreaterThan < Base
        private

        def solr_value(value = @value)
          solr_value = super
          solr_value = "\"#{solr_value}\"" if solr_value.index(' ')
          solr_value
        end

        def to_solr_conditional
          "{#{solr_value} TO *}"
        end
      end

      # 
      # Results must have field with value greater than or equal to given value
      #
      class GreaterThanOrEqualTo < Base
        private

        def solr_value(value = @value)
          solr_value = super
          solr_value = "\"#{solr_value}\"" if solr_value.index(' ')
          solr_value
        end

        def to_solr_conditional
          "[#{solr_value} TO *]"
        end
      end

      # 
      # Results must have field with value in given range
      #
      class Between < Base
        private

        def solr_value(value = @value)
          solr_value = super
          solr_value = "\"#{solr_value}\"" if solr_value.index(' ')
          solr_value
        end

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
      # Results must have a field with a value that begins with the argument.
      # Most useful for strings, but in theory will work with anything.
      #
      class StartingWith < Base
        private

        def to_solr_conditional
          "#{solr_value(@value)}*"
        end
      end
    end
  end
end
