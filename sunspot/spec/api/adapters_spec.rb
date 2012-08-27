require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Adapters::InstanceAdapter do
  it "finds adapter by superclass" do
    Sunspot::Adapters::InstanceAdapter::for(Model).should be(AbstractModelInstanceAdapter)
  end

  it "finds adapter by mixin" do
    Sunspot::Adapters::InstanceAdapter::for(MixModel).should be(MixInModelInstanceAdapter)
  end

  it 'throws NoAdapterError if anonymous module passed in' do
    lambda do
      Sunspot::Adapters::InstanceAdapter::for(Module.new)
    end.should raise_error(Sunspot::NoAdapterError)
  end
end

describe Sunspot::Adapters::DataAccessor do
  it "finds adapter by superclass" do
    Sunspot::Adapters::DataAccessor::for(Model).should be(AbstractModelDataAccessor)
  end

  it "finds adapter by mixin" do
    Sunspot::Adapters::DataAccessor::for(MixModel).should be(MixInModelDataAccessor)
  end

  it 'throws NoAdapterError if anonymous module passed in' do
    lambda do
      Sunspot::Adapters::DataAccessor::for(Module.new)
    end.should raise_error(Sunspot::NoAdapterError)
  end
end

describe Sunspot::Adapters::Registry do
  let(:registry){ Sunspot::Adapters::Registry.new }
  let(:abstractclass_accessor){ Sunspot::Adapters::DataAccessor::for(AbstractModel) }
  let(:superclass_accessor){ Sunspot::Adapters::DataAccessor::for(Model) }
  let(:mixin_accessor){ Sunspot::Adapters::DataAccessor::for(MixModel) }

  it "registers and retrieves a data accessor for abstractclass" do
      registry.retrieve(AbstractModel).should be_a(abstractclass_accessor)
  end

  it "registers and retrieves a data accessor for superclass" do
      registry.retrieve(Model).should be_a(superclass_accessor)
  end

  it "registers and retrieves a data accessor for mixin" do
      registry.retrieve(MixModel).should be_a(mixin_accessor)
  end

  it "injects inherited attributes" do
    AbstractModelDataAccessor.any_instance.stub(:inherited_attributes).and_return([:to_be_injected])
    in_registry_data_accessor = registry.retrieve(AbstractModel)
    in_registry_data_accessor.to_be_injected = "value"
    registry.retrieve(Model).to_be_injected.should == "value"
  end

  it "not overrides inherited attributes" do
    AbstractModelDataAccessor.any_instance.stub(:inherited_attributes).and_return([:to_be_injected])
    parent_data_accessor = registry.retrieve(AbstractModel)
    current_data_accessor = registry.retrieve(Model)
    parent_data_accessor.to_be_injected = "value"
    current_data_accessor.to_be_injected = "safe-value"
    registry.retrieve(Model).to_be_injected.should == "safe-value"
  end
end
