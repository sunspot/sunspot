module Sunspot
  class InstantiatedFacet < Facet
    def populate_instances!
      ids = rows.map { |row| row.value }
      reference_class = Sunspot::Util.full_const_get(@field.reference.to_s)
      accessor = Adapters::DataAccessor.create(reference_class)
      instance_map = accessor.load_all(ids).inject({}) do |map, instance|
        map[Adapters::InstanceAdapter.adapt(instance).id] = instance
        map
      end
      for row in rows
        row.instance = instance_map[row.value]
      end
    end

    private

    def new_row(pair)
      InstantiatedFacetRow.new(pair, self)
    end
  end
end
