module Sunspot
  class Search
    class FieldFacet < QueryFacet
      alias_method :field_name, :name

      def initialize(field, search, options) #:nodoc:
        super(field.name, search, options)
        @field = field
      end

      def rows
        @rows ||=
          begin
            rows = super
            has_query_facets = !rows.empty?
            if @search.facet_response['facet_fields']
              if data = @search.facet_response['facet_fields'][@field.indexed_name]
                data.each_slice(2) do |value, count|
                  rows << FacetRow.new(@field.cast(value), count, self)
                end
              end
            end
            sort_rows!(rows) if has_query_facets
            rows
          end
      end

      def populate_instances #:nodoc:
        if reference = @field.reference
          values_hash = rows.inject({}) do |hash, row|
            hash[row.value] = row
            hash
          end
          instances = Adapters::DataAccessor.create(Sunspot::Util.full_const_get(reference)).load_all(
            values_hash.keys
          )
          instances.each do |instance|
            values_hash[Adapters::InstanceAdapter.adapt(instance).id].instance = instance
          end
        end
      end
    end
  end
end
