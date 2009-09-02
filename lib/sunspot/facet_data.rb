require 'enumerator'

module Sunspot
  module FacetData
    class Abstract
      attr_reader :field #:nodoc:

      def reference
        @field.reference if @field
      end

      def cast(value)
        if @field
          @field.cast(value)
        else
          value
        end
      end

      def row_value(value)
        cast(value)
      end
    end

    class FieldFacetData < Abstract
      def initialize(facet_values, field) #:nodoc:
        @facet_values, @field = facet_values, field
      end

      # The name of the field that contains this facet's values
      #
      # ==== Returns
      #
      # Symbol:: The field name
      # 
      def name
        @field.name
      end

      # The rows returned for this facet.
      #
      # ==== Returns
      #
      # Array:: Collection of FacetRow objects, in the order returned by Solr
      # 
      def rows
        @rows ||=
          begin
            rows = []
            @facet_values.each_slice(2) do |value, count|
              rows << yield(row_value(value), count)
            end
            rows
          end
      end
    end

    class DateFacetData < FieldFacetData
      def initialize(facet_values, field) #:nodoc:
        @gap = facet_values.delete('gap')[/\+(\d+)SECONDS/,1].to_i
        %w(start end).each { |key| facet_values.delete(key) }
        super(facet_values.to_a.flatten, field)
      end

      #
      # Get the rows of this date facet, which are instances of DateFacetRow.
      # The rows will always be sorted in chronological order.
      #
      #--
      #
      # The date facet info comes back from Solr as a hash, so we need to sort
      # it manually. FIXME this currently assumes we want to do a "lexical"
      # sort, but we should support count sort as well, even if it's not a
      # common use case.
      #
      def rows(&block)
        super(&block).sort { |a, b| a.value.first <=> b.value.first }
      end

      private

      def row_value(value)
        cast(value)..(cast(value) + @gap)
      end
    end

    class QueryFacetData < Abstract
      def initialize(outgoing_query_facet, row_data) #:nodoc:
        @outgoing_query_facet, @row_data = outgoing_query_facet, row_data
        @field = @outgoing_query_facet.field
      end

      def name
        outgoing_query_facet.name
      end

      # 
      # Get the rows associated with this query facet. Returned rows are always
      # ordered by count.
      #
      # ==== Returns
      #
      # Array:: Collection of QueryFacetRow objects, ordered by count
      #
      def rows
        @rows ||=
          begin
            rows = []
            options = @outgoing_query_facet.options
            minimum_count =
              if options[:zeros] then 0
              elsif options[:minimum_count] then options[:minimum_count]
              else 1
              end
            for outgoing_row in  @outgoing_query_facet.rows
              row_query = outgoing_row.to_boolean_phrase
              if @row_data.has_key?(row_query)
                row = yield(outgoing_row.label, @row_data[row_query])
                rows << row if row.count >= minimum_count
              end
            end
            if options[:sort] == :index || !options[:limit] && options[:sort] != :count
              if rows.all? { |row| row.value.respond_to?(:<=>) }
                rows.sort! { |x, y| x.value <=> y.value }
              end
            else
              rows.sort! { |x, y| y.count <=> x.count }
            end
            if limit = options[:limit]
              rows[0, limit]
            else
              rows
            end
          end
      end
    end
  end
end
