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
    search = Sunspot.search(Post) { near(ORIGIN, 20) }
    search.results.to_set.should == @posts[0..2].to_set
  end

  it 'should perform a radial search with fulltext matching' do
    search = Sunspot.search(Post) do
      keywords 'teacup'
      near(ORIGIN, 20)
    end
    search.results.should == [@posts[1]]
  end

  it 'should order by arbitrary field' do
    search = Sunspot.search(Post) do
      near(ORIGIN, 20)
      order_by(:blog_id)
    end
    search.results.should == @posts[0..2].reverse
  end

  it 'should order by geo distance' do
    search = Sunspot.search(Post) do
      near(ORIGIN, 20)
      order_by(:distance)
    end
    search.results.should == @posts[0..2]
  end
end
