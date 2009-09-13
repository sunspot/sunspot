module Sunspot
  #
  # InstantiatedFacet instances allow access to a model instance based on a
  # primary key stored in facet rows' values. The rows are hydrated lazily, but
  # all rows are hydrated the first time #instance is called on any of the rows.
  #
  # The #rows method returns InstantiatedFacetRow objects.
  #
  class InstantiatedFacet < Facet
    # 
    # Hydrate all rows for the facet. For data accessors that can efficiently
    # batch load, this is more efficient than individually lazy-loading
    # instances for each row, but allows us to still stay lazy and not do work
    # in the persistent store if the instances are not needed.
    #
    def populate_instances! #:nodoc:
      ids = rows.map { |row| row.value }
      reference_class = Sunspot::Util.full_const_get(@facet_data.reference.to_s)
      accessor = Adapters::DataAccessor.create(reference_class)
      instance_map = accessor.load_all(ids).inject({}) do |map, instance|
        map[Adapters::InstanceAdapter.adapt(instance).id] = instance
        map
      end
      for row in rows
        row.instance = instance_map[row.value]
      end
    end

    def rows
      @facet_data.rows { |value, count| InstantiatedFacetRow.new(value, count, self) }
    end

    private

    # 
    # Override the Facet#new_row method to return an InstantiateFacetRow
    #
    def new_row(pair)
      InstantiatedFacetRow.new(pair, self)
    end
  end
end
