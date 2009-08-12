module Sunspot
  module Query
    # 
    # The Sort class is a query component representing a sort by a given field.
    # 
    module Sort #:nodoc:
      DIRECTIONS = {
        :asc => 'asc',
        :ascending => 'asc',
        :desc => 'desc',
        :descending => 'desc'
      }

      class <<self
        def special(name)
          special_class_name = "#{Util.camel_case(name.to_s)}Sort"
          if const_defined?(special_class_name) && special_class_name != 'FieldSort'
            const_get(special_class_name)
          end
        end
      end

      class Abstract
        def initialize(direction)
          @direction = (direction || :asc).to_sym
        end

        private

        def direction_for_solr
          DIRECTIONS[@direction] || 
            raise(
              ArgumentError,
              "Unknown sort direction #{@direction}. Acceptable input is: #{DIRECTIONS.keys.map { |input| input.inspect } * ', '}"
          )
        end
      end

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

      class RandomSort < Abstract
        def to_param
          "random_#{rand(1<<16)} #{direction_for_solr}"
        end
      end

      class ScoreSort < Abstract
        def to_param
          "score #{direction_for_solr}"
        end
      end

      class DistanceSort < Abstract
        def to_param
          "geo_distance #{direction_for_solr}"
        end
      end
    end
  end
end
