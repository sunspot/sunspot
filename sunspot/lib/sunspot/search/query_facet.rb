module Sunspot
  module Search
    class QueryFacet
      RequestedFacet = Struct.new(:label, :boolean_phrase) #:nodoc:

      attr_reader :name

      def initialize(name, search, options) #:nodoc:
        @name, @search, @options = name, search, options
        @requested_facets = []
      end

      def rows(options = {})
        @rows ||=
          begin
            data = @search.facet_response['facet_queries']
            rows = []
            minimum_count =
              case
              when @options[:minimum_count] then @options[:minimum_count]
              when @options[:zeros] then 0
              else 1
              end
            @requested_facets.each do |requested_facet|
              count = data[requested_facet.boolean_phrase] || 0
              if count >= minimum_count
                rows << FacetRow.new(requested_facet.label, count, self)
              end
            end
            sort_rows!(rows)
          end
      end

      def add_row(label, boolean_phrase) #:nodoc:
        @requested_facets << RequestedFacet.new(label, boolean_phrase)
      end

      private

      def sort_rows!(rows)
        case @options[:sort] || (:count if limit)
        when :count
          rows.sort! { |lrow, rrow| rrow.count <=> lrow.count }
        when :index
          rows.sort! do |lrow, rrow|
            if lrow.respond_to?(:<=>)
              lrow.value <=> rrow.value
            elsif lrow.respond_to?(:first) && rrow.respond_to?(:first) && lrow.first.respond_to?(:<=>)
              lrow.first.value <=> rrow.first.value
            else
              lrow.value.to_s <=> rrow.value.to_s
            end
          end
        end
        if limit
          rows.replace(rows.first(limit))
        end
        rows
      end

      def limit
        return @limit if defined?(@limit)
        @limit = (@options[:limit].to_i if @options[:limit].to_i > 0)
      end
    end
  end
end
