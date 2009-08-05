describe 'local search' do
  ORIGIN = [40.71405, -73.53317]
  before :each do
    Sunspot.remove_all
    @posts = [
      ORIGIN,
      [40.725304, -73.997211],
      [40.800069, -73.962283],
      [43.706488, -72.292233],
      [38.920303, -77.110934],
      [47.661557, -122.349938]
    ].map { |pair| Post.new(:coordinates => pair) }
    Sunspot.index!(@posts)
  end

  it 'should find all the posts within a given radius' do
    search = Sunspot.search { near(ORIGIN) }
    search.results.should == @posts[0..2]
  end
end
