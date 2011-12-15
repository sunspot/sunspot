module Sunspot
  module Query
    class QueryFacet < Connective::Conjunction

      def initialize(options = {}, negated = false)
        if exclude_filters = options[:exclude]
          @exclude_tag = Util.Array(exclude_filters).map do |filter|
            filter.tag
          end.join(',')
        end
        super(negated)
      end


      def to_params
        if @components.empty?
          {}
        else
          {
            :facet => 'true',
            :"facet.query" => to_boolean_phrase
          }
        end
      end

      def to_boolean_phrase
        "#{to_local_params}#{super}"
      end

      private

      def local_params
        @local_params ||=
          begin
            local_params = {}
            local_params[:ex] = @exclude_tag if @exclude_tag
            local_params
          end
      end

      def to_local_params
        if local_params.empty?
          ''
        else
          pairs = local_params.map do |key, value|
            "#{key}=#{value}"
          end
          "{!#{pairs.join(' ')}}"
        end
      end 
    end
  end
end
