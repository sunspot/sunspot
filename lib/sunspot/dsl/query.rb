module Sunspot
  module DSL
    class Query
      def initialize(query)
        @query = query 
      end

      def keywords(keywords)
        @query.keywords = keywords
      end

      def with
        @conditions_builder ||= ::Sunspot::DSL::Scope::implementation(@query.field_names).new(@query)
      end

      def without(*instances)
        if instances.empty?
          @negative_conditions_builder ||= ::Sunspot::DSL::Scope::implementation(@query.field_names).new(@query, true)
        else
          for instance in instances.flatten
            @query.add_negative_scope(Sunspot::Restriction::SameAs.new(instance))
          end
        end
      end

      def paginate(options = {})
        page = options.delete(:page) || raise(ArgumentError, "paginate requires a :page argument")
        per_page = options.delete(:per_page)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page)
      end

      def order_by(field_name, direction = nil)
        @query.order_by(field_name, direction)
      end
    end
  end
end
