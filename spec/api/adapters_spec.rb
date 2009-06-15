require File.join(File.dirname(__FILE__), 'spec_helper')

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
