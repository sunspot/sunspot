module Sunspot
  module DSL
    class FieldGroup
      def initialize(query, setup, group)
        @query, @setup, @group = query, setup, group
      end

      #
      # Sets the number of results (documents) to return for each group.
      # Defaults to 1.
      #
      def limit(num)
        @group.limit = num
      end

      #
      # If true, includes the number of groups that have matched the query.
      # Defaults to false.
      #
      def ngroups(val)
        @group.ngroups = val 
      end

      #
      # If true, facet counts are based on the most relevant document of each group matching the query.
      # This feature is only available on Solr 3.4+
      # Defaults to false.
      #
      def truncate(val)
        @group.truncate = val 
      end

      # Specify the order that results should be returned in. This method can
      # be called multiple times; precedence will be in the order given.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: the field to use for ordering
      # direction<Symbol>:: :asc or :desc (default :asc)
      #
      def order_by(field_name, direction = nil)
        sort =
          if special = Sunspot::Query::Sort.special(field_name)
            special.new(direction)
          else
            Sunspot::Query::Sort::FieldSort.new(
              @setup.field(field_name), direction
            )
          end
        @group.add_sort(sort)
      end
    end
  end
end
