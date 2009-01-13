require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'pagination' do
  before :all do
    Sunspot.remove_all
    @posts = (0..19).map do |i|
      Post.new(:blog_id => i)
    end
    Sunspot.index(*@posts)
  end

  it 'should return all by default' do
    results = Sunspot.search(Post) { order_by :blog_id }.results
    results.should == @posts
  end

  it 'should return first page of 10' do
    results = Sunspot.search(Post) do
      order_by :blog_id
      paginate :page => 1, :per_page => 10
    end.results
    results.should == @posts[0,10]
  end

  it 'should return second page of 10' do
    results = Sunspot.search(Post) do
      order_by :blog_id
      paginate :page => 2, :per_page => 10
    end.results
    results.should == @posts[10,10]
  end
end
