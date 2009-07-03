module Sunspot
  class Query
    #
    # Encapsulates a query component representing a field facet. Users create
    # instances using DSL::Query#facet
    #
    class FieldFacet #:nodoc:
      def initialize(field, options)
        @field, @options = field, options
      end

      # ==== Returns
      #
      # Hash:: solr-ruby params for this field facet
      #
      def to_params
        params = { :"facet.field" => [@field.indexed_name], 'facet' => 'true' }
        params[param_key(:sort)] = 
          case @options[:sort]
          when :count then 'true'
          when :index then 'false'
          when nil
          else raise(ArgumentError, 'Allowed facet sort options are :count and :index')
          end
        params[param_key(:limit)] = @options[:limit]
        params[param_key(:mincount)] =
          if @options[:minimum_count] then @options[:minimum_count]
          elsif @options[:zeros] then 0
          else 1
          end
        params
      end

      private

      def param_key(name)
        :"f.#{@field.indexed_name}.facet.#{name}"
      end
    end
  end
end
