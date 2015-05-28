module Sunspot
  module DSL
    class Group
      def initialize(setup, group)
        @setup, @group = setup, group
      end

      # Specify one or more fields for result grouping.
      #
      # ==== Parameters
      #
      # field_names...<Symbol>:: the fields to use for grouping
      #
      def field(*field_names, &block)
        field_names.each do |field_name|
          field = @setup.field(field_name)
          @group.add_field(field)
        end
      end

      # Specify a query to group results by.
      #
      # ==== Parameters
      #
      # label<Object>:: a label for this group; when #value is called on this
      #   group's results, this label will be returned.
      #
      def query(label, &block)
        group_query = Sunspot::Query::GroupQuery.new(label)
        Sunspot::Util.instance_eval_or_call(Scope.new(group_query, @setup), &block)
        @group.add_query(group_query)
      end

      #
      # Sets the number of results (documents) to return for each group.
      # Defaults to 1.
      #
      def limit(num)
        @group.limit = num
      end

      #
      # If set, facet counts are based on the most relevant document of
      # each group matching the query.
      #
      # Supported in Solr 3.4 and above.
      #
      # ==== Example
      #
      #     Sunspot.search(Post) do
      #       group :title do
      #         truncate
      #       end
      #
      #       facet :title, :extra => :any
      #     end
      #
      def truncate
        @group.truncate = true
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

      #
      # Specify that results should be ordered based on a
      # FunctionQuery - http://wiki.apache.org/solr/FunctionQuery
      # Solr 3.1 and up
      #
      #  For example, to order by field1 + (field2*field3):
      #
      #    order_by_function :sum, :field1, [:product, :field2, :field3], :desc
      #
      # ==== Parameters
      # function_name<Symbol>::
      #   the function to run
      # arguments::
      #   the arguments for this function.
      #   - Symbol for a field or function name
      #   - Array for a nested function
      #   - String for a literal constant
      # direction<Symbol>::
      #   :asc or :desc
      def order_by_function(*args)
        @group.add_sort(
          Sunspot::Query::Sort::FunctionSort.new(@setup,args)
        )
      end
    end
  end
end
