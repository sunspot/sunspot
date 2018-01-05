module Sunspot
  module DSL
    class FieldStats #:nodoc:
      def initialize(query_stats, setup, search_stats) #:nodoc:
        @query_stats, @setup, @search_stats = query_stats, setup, search_stats
      end

      def facet *field_names
        field_names.each do |field_name|
          field = @setup.field(field_name)

          @query_stats.add_facet(field)
          @search_stats.add_facet(field)
        end
      end

      def json_facet(field_name, options = {})
        field = @setup.field(field_name)

        facet =
            if options[:time_range]
              unless field.type.is_a?(Sunspot::Type::TimeType)
                raise(
                    ArgumentError,
                    ':time_range can only be specified for Date or Time fields'
                )
              end
              Sunspot::Query::DateFieldJsonFacet.new(field, options)
            elsif options[:range]
              unless [Sunspot::Type::TimeType, Sunspot::Type::FloatType, Sunspot::Type::IntegerType ].inject(false){|res,type| res || field.type.is_a?(type)}
                raise(
                    ArgumentError,
                    ':range can only be specified for date or numeric fields'
                )
              end
              Sunspot::Query::RangeJsonFacet.new(field, options)
            else
              Sunspot::Query::FieldJsonFacet.new(field, options)
            end

        @query_stats.add_json_facet(facet)
      end

    end
  end
end
