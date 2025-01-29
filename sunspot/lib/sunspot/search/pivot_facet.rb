module Sunspot
  module Search
    class PivotFacet
      class Row
        def initialize(fields, pivot, setup)
          # ordering is important here!
          @field, *@deeper_fields = *fields
          @pivot = pivot
          @setup = setup
        end

        attr_reader :field, :deeper_fields

        def result
          @pivot
        end

        def pivot
          result['pivot'].map { |p| Row.new(deeper_fields, p, @setup) }
        end

        def range(field_name)
          indexed_name = @setup.field(field_name).indexed_name
          return unless result['ranges'][indexed_name]
          PivotRange.new(result['ranges'][indexed_name])
        end
      end

      class PivotRange
        def initialize(range)
          @range = range
        end

        def counts
          #probably should be just like the RangeFacet returning FacetRows
          @range['counts'].each_slice(2).to_h
        end

        def gap
          @range['gap']
        end

        def start
          @range['start']
        end

        def end
          @range['end']
        end
      end

      def initialize(fields, setup, search, options)
        @fields, @setup, @search, @options = fields, setup, search, options
      end

      def rows
        @rows ||= @search.
          facet_response['facet_pivot'][range_name].
          map { |p| Row.new(@fields, p, @setup) }
      end

      def range_name
        @fields.map(&:indexed_name).join(',')
      end
    end
  end
end
