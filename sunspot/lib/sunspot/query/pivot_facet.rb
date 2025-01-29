module Sunspot
  module Query
    # Add a facet class for pivoting ranges
    class PivotFacet < AbstractFieldFacet
      def initialize(fields, options)
        @fields = fields
        # This facet operates on mutiple fields
        super(nil, options)
      end

      # ammended not to rely on @field
      def qualified_param(param)
        :"facet.pivot.#{param}"
      end

      def to_params
        super.tap do |params|
          # use array so that multiple facet.pivot appear in the search
          # string rather than the last facet.pivot key added to the params
          # see:
          # * https://github.com/sunspot/sunspot/blob/3328212da79178319e98699d408f14513855d3c0/sunspot/lib/sunspot/query/common_query.rb#L81
          # * https://github.com/sunspot/sunspot/blob/3328212da79178319e98699d408f14513855d3c0/sunspot/lib/sunspot/util.rb#L236
          #
          params[:"facet.pivot"] = [field_names_with_local_params]
        end
      end

      private

      def local_params
        @local_params ||=
          {}.tap do |local_params|
            local_params[:range] = @options[:range] if @options[:range]
            local_params[:stats] = @options[:stats] if @options[:stats]
            local_params[:query] = @options[:query] if @options[:query]
          end
      end

      def field_names_with_local_params
        if local_params.empty?
          field_names.join(',')
        else
          pairs = local_params.map { |key, value| "#{key}=#{value}" }
          "{!#{pairs.join(' ')}}#{field_names.join(',')}"
        end
      end

      def field_names
        @fields.map(&:indexed_name)
      end
    end
  end
end
