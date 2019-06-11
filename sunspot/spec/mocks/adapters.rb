class AbstractModel
end

class Model < AbstractModel
end

class UnseenModel < AbstractModel
end

class ModelWithPrefixId < AbstractModel
  def id
    1
  end
end

Sunspot.setup(ModelWithPrefixId) do
  id_prefix { "USERDATA!" }
end

class ModelWithNestedPrefixId < AbstractModel
  def id
    1
  end
end

Sunspot.setup(ModelWithNestedPrefixId) do
  id_prefix { "USER!USERDATA!" }
end

class ModelWithoutPrefixId < AbstractModel
  def id
    1
  end
end

Sunspot.setup(ModelWithoutPrefixId) do
end


class AbstractModelInstanceAdapter < Sunspot::Adapters::InstanceAdapter
  def id
    @instance.id
  end
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

