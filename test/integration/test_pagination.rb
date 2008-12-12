require File.join(File.dirname(__FILE__), 'test_helper')

class TestPagination < Test::Unit::TestCase
  before :all do
    Sunspot.remove_all
    @posts = (0..19).map do |i|
      Post.new(:blog_id => i)
    end
    Sunspot.index(*@posts)
  end

  should 'return all by default' do
    results = Sunspot.search(Post) { order_by :blog_id }.results
    results.should == @posts
  end
end
