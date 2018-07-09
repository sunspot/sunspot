require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'indexing child documents fields', :type => :indexer do
  it '--> TEST <--' do
    children = Array.new(3) { Child.new }
    parent   = Person.new(children: children)
    session.index parent
  end
end