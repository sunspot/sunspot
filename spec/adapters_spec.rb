_dir_ = File.dirname(__FILE__)

require File.join(_dir_, 'spec_helper')
require File.join(_dir_, 'fixtures', 'adapters')

describe Sunspot::Adapters::InstanceAdapter do
  it "finds adapter by superclass" do
    Sunspot::Adapters::InstanceAdapter::for(Model).should be(AbstractModelInstanceAdapter)
  end

  it "finds adapter by mixin" do
    Sunspot::Adapters::InstanceAdapter::for(MixModel).should be(MixInModelInstanceAdapter)
  end
end

describe Sunspot::Adapters::DataAccessor do
  it "finds adapter by superclass" do
    Sunspot::Adapters::DataAccessor::for(Model).should be(AbstractModelDataAccessor)
  end

  it "finds adapter by mixin" do
    Sunspot::Adapters::DataAccessor::for(MixModel).should be(MixInModelDataAccessor)
  end
end