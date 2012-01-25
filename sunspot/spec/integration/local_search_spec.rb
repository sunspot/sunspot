require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'local search' do
  ORIGIN = [40.7246062, -73.9969018]
  LOCATIONS = [
    [40.7246062, -73.9969018], # dr5rsjtn50yf
    [40.724606, -73.996902],   # dr5rsjtn50y9
    [40.724606, -73.996901],   # dr5rsjtn50z3
    [40.72461, -73.996906]     # dr5rsjtn51ec
  ].map { |lat, lng| Sunspot::Util::Coordinates.new(lat, lng) }

  before :each do
    Sunspot.remove_all
  end

  describe 'without fulltext' do
    before :each do
      @posts = LOCATIONS.map do |location|
        Post.new(:coordinates => location)
      end
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        with(:coordinates).near(ORIGIN[0], ORIGIN[1], :precision_factor => 4.0)
      end
    end

    it 'should return results in geo order' do
      @search.results.should == @posts
    end

    it 'should asssign higher score to closer locations' do
      hits = @search.hits
      hits[1..-1].each_with_index do |hit, i|
        hit.score.should < hits[i].score
      end
    end
  end

  describe 'with fulltext' do
    before :each do
      @posts = [
        Post.new(:title => 'pizza', :coordinates => LOCATIONS[0]),
        Post.new(:title => 'pizza', :coordinates => LOCATIONS[1]),
        Post.new(:title => 'pasta calzone pizza antipasti', :coordinates => LOCATIONS[1])
      ]
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        keywords 'pizza'
        with(:coordinates).near(ORIGIN[0], ORIGIN[1])
      end
    end

    it 'should take both fulltext and distance into account in ordering' do
      @search.results.should == @posts
    end

    it 'should take both fulltext and distance into account in scoring' do
      hits = @search.hits
      hits[1..-1].each_with_index do |hit, i|
        hit.score.should < hits[i].score
      end
    end
  end
end
