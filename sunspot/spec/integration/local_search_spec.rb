require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'local search' do
  ORIGIN = [40.6749113, -73.9648859]
  before :each do
    Sunspot.remove_all
    @posts = [
      Post.new(:coordinates => ORIGIN),
      Post.new(:coordinates => [40.725304, -73.997211], :title => 'teacup'),
      Post.new(:coordinates => [40.800069, -73.962283]),
      Post.new(:coordinates => [43.706488, -72.292233]),
      Post.new(:coordinates => [38.920303, -77.110934], :title => 'teacup'),
      Post.new(:coordinates => [47.661557, -122.349938])
    ]
    @posts.each_with_index { |post, i| post.blog_id = @posts.length - i }
    Sunspot.index!(@posts)
  end

  it 'should find all the posts within a given radius' do
    search = Sunspot.search(Post) { |query| query.near(ORIGIN, :distance => 20) }
    search.results.to_set.should == @posts[0..2].to_set
  end

  it 'should perform a radial search with fulltext matching' do
    search = Sunspot.search(Post) do |query|
      query.keywords 'teacup'
      query.near(ORIGIN, :distance => 20)
    end
    search.results.should == [@posts[1]]
  end

  it 'should use dismax for fulltext matching in local search' do
    lambda do
      search = Sunspot.new_search(Post)
      search.build do |query|
        query.keywords 'teacup['
        query.near(ORIGIN, :distance => 20)
      end
      search.execute
    end.should_not raise_error
  end

  it 'should perform a radial search with attribute scoping' do
    search = Sunspot.search(Post) do |query|
      query.near(ORIGIN, :distance => 20)
      query.with(:title, 'teacup')
    end
    search.results.should == [@posts[1]]
  end

  it 'should perform a radial search with attribute scoping and distance sorting' do
    search = Sunspot.search(Post) do |query|
      query.near(ORIGIN, :sort => true)
      query.with(:title, 'teacup')
    end
    search.results.should == [@posts[1], @posts[4]]
  end

  it 'should order by arbitrary field' do
    search = Sunspot.search(Post) do |query|
      query.near(ORIGIN, :distance => 20)
      query.order_by(:blog_id)
    end
    search.results.should == @posts[0..2].reverse
  end

  it 'should order by geo distance' do
    search = Sunspot.search(Post) do |query|
      query.near(ORIGIN, :distance => 20, :sort => true)
    end
    search.results.should == @posts[0..2]
  end

  it 'should order by geo distance with fulltext' do
    lambda do
      search = Sunspot.search(Post) do |query|
        query.fulltext('teacup')
        query.near(ORIGIN, :sort => true)
      end
    end.should_not raise_error
  end

  it 'should return geographical distance from origin' do
    search = Sunspot.search(Post) do |query|
      query.near(ORIGIN, :sort => true)
    end
    search.hits.each do |hit|
      hit.distance.should_not be_nil
    end
  end
end
