require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'pagination' do
  before :all do
    Sunspot.remove_all
    @posts = (0..19).map do |i|
      Post.new(:blog_id => i)
    end
    Sunspot.index!(*@posts)
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

  it 'should return pages with offsets' do
    results = Sunspot.search(Post) do
      order_by :blog_id
      paginate :page => 2, :per_page => 5, :offset => 3
    end.results

    # page 1 is 3, 4, 5, 6, 7
    # page 2 is 8, 9, 10, 11, 12
    results.should == @posts[8,5]
  end
end
