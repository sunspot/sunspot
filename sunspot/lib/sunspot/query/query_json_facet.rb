module Sunspot
  module Query
    class QueryJsonFacet < AbstractJsonFieldFacet

      def initialize(field, options, setup)
        raise Exception.new('Need to specify a query') if options[:query].nil?
        @query = options[:query]
        super
      end

      def field_name_with_local_params
        {
          @field.name => {
            type: 'query',
            q: @query,
            field: @field.indexed_name,
          }.merge!(init_params)
        }
      end
    end
  end
end
