class AbstractModel
end

class Model < AbstractModel
end

class AbstractModelInstanceAdapter < Sunspot::Adapters::InstanceAdapter
end

class AbstractModelDataAccessor < Sunspot::Adapters::DataAccessor
  attr_accessor :to_be_injected
end

Sunspot::Adapters::InstanceAdapter.register(AbstractModelInstanceAdapter, AbstractModel)
Sunspot::Adapters::DataAccessor.register(AbstractModelDataAccessor, AbstractModel)


module MixInModel
end

class MixModel
  include MixInModel
end

class MixInModelInstanceAdapter < Sunspot::Adapters::InstanceAdapter
end

class MixInModelDataAccessor < Sunspot::Adapters::DataAccessor
end

Sunspot::Adapters::InstanceAdapter.register(MixInModelInstanceAdapter, MixInModel)
Sunspot::Adapters::DataAccessor.register(MixInModelDataAccessor, MixInModel)

