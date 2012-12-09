module Sunspot
  module Query
    # 
    # The classes in this module implement query components that build sort
    # parameters for Solr. As well as regular sort on fields, there are several
    # "special" sorts that allow ordering for metrics calculated during the
    # search.
    # 
    module Sort #:nodoc: all
      DIRECTIONS = {
        :asc => 'asc',
        :ascending => 'asc',
        :desc => 'desc',
        :descending => 'desc'
      }

      class <<self
        # 
        # Certain field names are "special", referring to specific non-field
        # sorts, which are generally by other metrics associated with hits.
        #
        # XXX I'm not entirely convinced it's a good idea to prevent anyone from
        # ever sorting by a field named 'score', etc.
        #
        def special(name)
          special_class_name = "#{Util.camel_case(name.to_s)}Sort"
          if const_defined?(special_class_name) && special_class_name != 'FieldSort'
            const_get(special_class_name)
          end
        end
      end

      # 
      # Base class for sorts. All subclasses should implement the #to_param
      # method, which is a string that is then concatenated with other sort
      # strings by the SortComposite to form the sort parameter.
      #
      class Abstract
        def initialize(direction)
          @direction = (direction || :asc).to_sym
        end

        private

        # 
        # Translate fairly forgiving direction argument into solr direction
        #
        def direction_for_solr
          DIRECTIONS[@direction] || 
            raise(
              ArgumentError,
              "Unknown sort direction #{@direction}. Acceptable input is: #{DIRECTIONS.keys.map { |input| input.inspect } * ', '}"
          )
        end
      end

      # 
      # A FieldSort is the usual kind of sort, by the value of a particular
      # field, ascending or descending
      #
      class FieldSort < Abstract
        def initialize(field, direction = nil)
          if field.multiple?
            raise(ArgumentError, "#{field.name} cannot be used for ordering because it is a multiple-value field")
          end
          @field, @direction = field, (direction || :asc).to_sym
        end

        def to_param
          "#{@field.indexed_name.to_sym} #{direction_for_solr}"
        end
      end

      # 
      # A RandomSort uses Solr's random field functionality to sort results
      # (usually) randomly.
      #
      class RandomSort < Abstract
        def initialize(options_or_direction=nil)
          if options_or_direction.is_a?(Hash)
            @seed, @direction = options_or_direction[:seed], options_or_direction[:direction]
					else
            @direction = options_or_direction
          end

          @direction = (@direction || :asc).to_sym
        end

        def to_param
          "random_#{@seed || rand(1<<6)} #{direction_for_solr}"
        end
      end

      # 
      # A ScoreSort sorts by keyword relevance score. This is only useful when
      # performing fulltext search.
      #
      class ScoreSort < Abstract
        def to_param
          "score #{direction_for_solr}"
        end
      end

      #
      # A GeodistSort sorts by distance from a given point.
      #
      class GeodistSort < FieldSort
        def initialize(field, lat, lon, direction)
          @lat, @lon = lat, lon
          super(field, direction)
        end

        def to_param
          "geodist(#{@field.indexed_name.to_sym},#{@lat},#{@lon}) #{direction_for_solr}"
        end
      end
    end
  end
end
