module Sunspot
  module Search
    # 
    # A FieldFacet is a facet whose rows are all values for a certain field, in
    # contrast to a QueryFacet, whose rows represent arbitrary queries.
    #
    class FieldFacet < QueryFacet
      def initialize(field, search, options) #:nodoc:
        super((options[:name] || field.name).to_sym, search, options)
        @field = field
      end

      def field_name
        @field.name
      end

      # 
      # Get the rows returned for this facet.
      #
      # ==== Options (options)
      #
      # :verify::
      #   Only return rows for which the referenced object exists in the data
      #   store. This option is ignored unless the field associated with this
      #   facet is configured with a :references argument.
      #
      # ==== Returns
      #
      # Array:: Array of FacetRow objects
      #
      def rows(options = {})
        if options[:verify]
          verified_rows
        else
          @rows ||=
            begin
              rows = super
              has_query_facets = !rows.empty?
              if @search.facet_response['facet_fields']
                if data = @search.facet_response['facet_fields'][key]
                  data.each_slice(2) do |value, count|
                    row = FacetRow.new(@field.cast(value), count, self)
                    rows << row
                  end
                end
              end
              sort_rows!(rows) if has_query_facets
              rows
            end
        end
      end

      # 
      # If this facet references a model class, populate the rows with instances
      # of the model class by loading them out of the appropriate adapter.
      #
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
          true
        end
      end

      private

      def verified_rows
        if @field.reference
          @verified_rows ||= rows.select { |row| row.instance }
        else
          rows
        end
      end
      
      def key
        @key ||= (@options[:name] || @field.indexed_name).to_s
      end
    end
  end
end
