require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Adapters::ActiveRecordDataAccessor, '#load_all' do
  before(:each) do
    @clazz = stub(:clazz, :primary_key => :id)
    @accessor = Sunspot::Rails::Adapters::ActiveRecordDataAccessor.new(@clazz)
  end

  it 'calls #all on the active record class if no scope was given' do
    @clazz.should_receive(:all).with(:conditions => {:id => [1]})

    @accessor.load_all [1]
  end

  it 'calls #all on the given scope if one was given' do
    scope = stub(:scope)
    scope.should_receive(:all).with(:conditions => {:id => [1]})

    @accessor.load_all [1], :activerecord_scope => scope
  end
end
