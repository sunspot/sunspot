module Sunspot
  class Search
    class QueryFacet
      RequestedFacet = Struct.new(:label, :boolean_phrase) #:nodoc:

      include FacetInstancePopulator

      attr_reader :name
      alias_method :field_name, :name

      def initialize(name, search, options, field = nil) #:nodoc:
        @name, @search, @options, @field = name, search, options, field
        @requested_facets = []
      end

      def rows
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
            case @options[:sort] || (:count if @options[:limit])
            when :count
              rows.sort! { |lrow, rrow| rrow.count <=> lrow.count }
            when :lexical
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
            if @options[:limit]
              rows.slice(0, @options[:limit])
            else
              rows
            end
          end
      end

      def add_row(label, boolean_phrase) #:nodoc:
        @requested_facets << RequestedFacet.new(label, boolean_phrase)
      end
    end
  end
end
