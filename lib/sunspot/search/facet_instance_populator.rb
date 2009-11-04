module Sunspot
  class Search
    module FacetInstancePopulator
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
