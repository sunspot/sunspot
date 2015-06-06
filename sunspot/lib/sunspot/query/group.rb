module Sunspot
  module Query
    #
    # A Group groups by the unique values of a given field, or by given queries.
    #
    class Group
      attr_accessor :limit, :truncate
      attr_reader :fields, :queries

      def initialize
        @sort = SortComposite.new
        @fields = []
        @queries = []
      end

      def add_field(field)
        if field.multiple?
          raise(ArgumentError, "#{field.name} cannot be used for grouping because it is a multiple-value field")
        end
        @fields << field
      end

      def add_query(query)
        @queries << query
      end

      def add_sort(sort)
        @sort << sort
      end

      def to_params
        params = {
          :group            => "true",
          :"group.ngroups"  => "true",
        }

        params.merge!(@sort.to_params("group."))
        params[:"group.field"] = @fields.map(&:indexed_name) if @fields.any?
        params[:"group.query"] = @queries.map(&:to_boolean_phrase) if @queries.any?
        params[:"group.limit"] = @limit if @limit
        params[:"group.truncate"] = @truncate if @truncate

        params
      end
    end
  end
end
