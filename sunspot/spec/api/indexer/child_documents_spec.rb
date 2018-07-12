require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'rsolr'

describe 'indexing child documents fields', :type => :indexer do
  it 'should index both parent and children' do
    children = Array.new(3) { |i| Child.new(name: "Child #{i}") }
    parent   = Parent.new(name: 'Test Parent', children: children)
    Sunspot.index!(parent)
    expect(Sunspot.search(Parent) { with :name, parent.name }.results).to be_one
    children.each do |child|
      expect(Sunspot.search(Child) { with :name, child.name }.results).to be_one
    end
  end
end