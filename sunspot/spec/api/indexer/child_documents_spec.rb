require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'indexing child documents fields', :type => :indexer do
  it 'should index both parent and children' do
    children = Array.new(3) { Child.new }
    parent   = Parent.new(name: 'Test Parent', children: children)
    Sunspot.index!(parent)
    expect(Sunspot.search(Parent) { with :name, parent.name }.results).to be_one
  end
end