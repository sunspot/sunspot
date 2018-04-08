module Sunspot
  module Query
    class AbstractJsonFieldFacet

      attr_accessor :field

      DISTINCT_STRATEGIES = [:unique, :hll]

      def initialize(field, options, setup)
        @field, @options, @setup = field, options, setup
      end

      def init_params
        params = {}
        params[:limit] = @options[:limit] unless @options[:limit].nil?
        params[:mincount] = @options[:minimum_count] unless @options[:minimum_count].nil?
        params[:sort] = { @options[:sort] => @options[:sort_type]||'desc' } unless @options[:sort].nil?
        params[:prefix] = @options[:prefix] unless @options[:prefix].nil?
        params[:offset] = @options[:offset] unless @options[:offset].nil?

        if !@options[:distinct].nil?
          dist_opts = @options[:distinct]
          raise Exception.new("Need to specify a strategy") if dist_opts[:strategy].nil?
          raise Exception.new("The strategy must be one of #{DISTINCT_STRATEGIES}") unless DISTINCT_STRATEGIES.include?(dist_opts[:strategy])
          @stategy = dist_opts[:strategy]
          @group_by = dist_opts[:group_by].nil? ? @field : @setup.field(dist_opts[:group_by])
          params[:field] = @group_by.indexed_name
          params[:facet] = {}
          params[:facet][:distinct] = "#{@stategy}(#{@field.indexed_name})"
        end

        params
      end

      def get_params
        query = field_name_with_local_params
        nested_params = recursive_nested_params(@options)

        if !nested_params.nil?
          query[@field.name][:facet] ||= {}
          query[@field.name][:facet].merge!(nested_params)
        end
        query
      end

      def to_params
        { 'json.facet' => self.get_params.to_json }
      end

      private

      def recursive_nested_params(options)
        if !options[:nested].nil? && options[:nested].is_a?(Hash)
          opts = options[:nested]
          field_name = opts[:field]

          options = Sunspot::Util.extract_options_from([opts])
          params = Sunspot::Util.parse_json_facet(field_name, options, @setup).field_name_with_local_params
          if !opts.nil?
            nested_params = recursive_nested_params(opts)
            params[field_name][:facet] = nested_params unless nested_params.nil?
          end

          params
        end
      end

    end
  end
end
