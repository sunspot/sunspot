module Sunspot
  module Query
    class FieldStats
      def initialize(field, options)
        @field, @options = field, options
        @facets = []
      end

      def add_facet field
        @facets << field
      end

      def add_json_facet(json_facet)
        @json_facet = json_facet
      end

      def to_params
        params = {}
        if !@json_facet.nil?
          params['json.facet'] = recursive_add_stats(@json_facet.get_params).to_json
        else
          params.merge!(:stats => true, :"stats.field" => [@field.indexed_name])
          params[facet_key] = @facets.map(&:indexed_name) unless @facets.empty?
        end
        params
      end

      STATS_FUNCTIONS = [:min, :max, :sum, :avg, :sumsq]

      def recursive_add_stats(query)
        query.keys.each do |k|
          if !query[k][:facet].nil?
            query[k][:facet] = recursive_add_stats(query[k][:facet])
          end
          query[k][:facet] ||= {}
          query[k][:sort] = { @options[:sort] => @options[:sort_type]||'desc' } unless @options[:sort].nil?
          query[k][:facet].merge!(json_stats_params)
        end
        query
      end

      def json_stats_params
        params = {}
        STATS_FUNCTIONS.each { |s| params[s] = "#{s.to_s}(#{@field.indexed_name})" }
        unless @options[:stats].nil?
          to_remove = STATS_FUNCTIONS - @options[:stats]
          to_remove.map { |s| params.delete(s)}
        end
        params
      end

      def facet_key
        qualified_param 'facet'
      end

      def qualified_param name
        :"f.#{@field.indexed_name}.stats.#{name}"
      end
    end
  end
end
