require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Adapters::InstanceAdapter do
  it "finds adapter by superclass" do
    expect(Sunspot::Adapters::InstanceAdapter::for(Model)).to be(AbstractModelInstanceAdapter)
  end

  it "finds adapter by mixin" do
    expect(Sunspot::Adapters::InstanceAdapter::for(MixModel)).to be(MixInModelInstanceAdapter)
  end

  it 'throws NoAdapterError if anonymous module passed in' do
    expect do
      Sunspot::Adapters::InstanceAdapter::for(Module.new)
    end.to raise_error(Sunspot::NoAdapterError)
  end

  it "registers adapters found by ancestor lookup with the descendant class" do
    expect(Sunspot::Adapters::InstanceAdapter::registered_adapter_for(UnseenModel)).to be(nil)
    Sunspot::Adapters::InstanceAdapter::for(UnseenModel)
    expect(Sunspot::Adapters::InstanceAdapter::registered_adapter_for(UnseenModel)).to be(AbstractModelInstanceAdapter)
  end

  it "appends ID prefix when configured" do
    expect(AbstractModelInstanceAdapter.new(ModelWithPrefixId.new).index_id).to eq "USERDATA!ModelWithPrefixId 1"
  end

  it "supports nested ID prefixes" do
    expect(AbstractModelInstanceAdapter.
      new(ModelWithNestedPrefixId.new).index_id).to eq "USER!USERDATA!ModelWithNestedPrefixId 1"
  end

  it "doesn't appends ID prefix when not configured" do
    expect(AbstractModelInstanceAdapter.new(ModelWithoutPrefixId.new).index_id).to eq "ModelWithoutPrefixId 1"
  end
end

describe Sunspot::Adapters::DataAccessor do
  it "finds adapter by superclass" do
    expect(Sunspot::Adapters::DataAccessor::for(Model)).to be(AbstractModelDataAccessor)
  end

  it "finds adapter by mixin" do
    expect(Sunspot::Adapters::DataAccessor::for(MixModel)).to be(MixInModelDataAccessor)
  end

  it 'throws NoAdapterError if anonymous module passed in' do
    expect do
      Sunspot::Adapters::DataAccessor::for(Module.new)
    end.to raise_error(Sunspot::NoAdapterError)
  end

  it "registers adapters found by ancestor lookup with the descendant class" do
    expect(Sunspot::Adapters::DataAccessor::registered_accessor_for(UnseenModel)).to be(nil)
    Sunspot::Adapters::DataAccessor::for(UnseenModel)
    expect(Sunspot::Adapters::DataAccessor::registered_accessor_for(UnseenModel)).to be(AbstractModelDataAccessor)
  end
end

describe Sunspot::Adapters::Registry do
  let(:registry){ Sunspot::Adapters::Registry.new }
  let(:abstractclass_accessor){ Sunspot::Adapters::DataAccessor::for(AbstractModel) }
  let(:superclass_accessor){ Sunspot::Adapters::DataAccessor::for(Model) }
  let(:mixin_accessor){ Sunspot::Adapters::DataAccessor::for(MixModel) }

  it "registers and retrieves a data accessor for abstractclass" do
      expect(registry.retrieve(AbstractModel)).to be_a(abstractclass_accessor)
  end

  it "registers and retrieves a data accessor for superclass" do
      expect(registry.retrieve(Model)).to be_a(superclass_accessor)
  end

  it "registers and retrieves a data accessor for mixin" do
      expect(registry.retrieve(MixModel)).to be_a(mixin_accessor)
  end

  it "injects inherited attributes" do
    allow_any_instance_of(AbstractModelDataAccessor).to receive(:inherited_attributes).and_return([:to_be_injected])
    in_registry_data_accessor = registry.retrieve(AbstractModel)
    in_registry_data_accessor.to_be_injected = "value"
    expect(registry.retrieve(Model).to_be_injected).to eq("value")
  end

  it "not overrides inherited attributes" do
    allow_any_instance_of(AbstractModelDataAccessor).to receive(:inherited_attributes).and_return([:to_be_injected])
    parent_data_accessor = registry.retrieve(AbstractModel)
    current_data_accessor = registry.retrieve(Model)
    parent_data_accessor.to_be_injected = "value"
    current_data_accessor.to_be_injected = "safe-value"
    expect(registry.retrieve(Model).to_be_injected).to eq("safe-value")
  end
end
