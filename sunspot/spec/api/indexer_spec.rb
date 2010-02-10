require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'indexer', :type => :indexer do
  it 'should completely wipe setup if class redefined (reloaded)' do
    Object::ReloadableClass = Class.new(MockRecord)
    Sunspot.setup(ReloadableClass) { string(:title) }
    Object.class_eval { remove_const(:ReloadableClass) }
    Object::ReloadableClass = Class.new(MockRecord)
    Sunspot.setup(ReloadableClass) {}
    lambda do
      Sunspot.search(ReloadableClass) { with(:title, 'title') }
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end
end
