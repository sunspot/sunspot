require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'stored fields' do
  before :all do
    Sunspot.remove_all
    Sunspot.index!(Post.new(:title => 'A Title'))
  end

  it 'should return stored fields' do
    Sunspot.search(Post).hits.first.stored(:title).should == 'A Title'
  end
end
