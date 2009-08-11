require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'keyword search' do
  describe 'generally' do
    before :all do
      Sunspot.remove_all
      @posts = []
      @posts << Post.new(:title => 'The toast elects the insufficient spirit',
                         :body => 'Does the wind write?')
      @posts << Post.new(:title => 'A nail abbreviates the recovering insight outside the moron',
                         :body => 'The interpreted strain scans the buffer around the upper temper')
      @posts << Post.new(:title => 'The toast abbreviates the recovering spirit',
                         :body => 'Does the wind interpret the buffer, moron?')
      Sunspot.index!(*@posts)
      @comment = Namespaced::Comment.new(:body => 'Hey there where ya goin, not exactly knowin, who says you have to call just one place toast.')
      Sunspot.index!(@comment)
    end

    it 'matches a single keyword out of a single field' do
      results = Sunspot.search(Post) { keywords 'toast' }.results
      [0, 2].each { |i| results.should include(@posts[i]) }
      [1].each { |i| results.should_not include(@posts[i]) }
    end

    it 'matches multiple words out of a single field' do
      results = Sunspot.search(Post) { keywords 'elects toast' }.results
      results.should == [@posts[0]]
    end

    it 'matches multiple words in multiple fields' do
      results = Sunspot.search(Post) { keywords 'toast wind' }.results
      [0, 2].each { |i| results.should include(@posts[i]) }
      [1].each { |i| results.should_not include(@posts[i]) }
    end

    it 'matches multiple types' do
      results = Sunspot.search(Post, Namespaced::Comment) do
        keywords 'toast'
      end.results
      [@posts[0], @posts[2], @comment].each  { |obj| results.should include(obj) }
      results.should_not include(@posts[1])
    end

    it 'matches keywords from only the fields specified' do
      results = Sunspot.search(Post) do
        keywords 'moron', :fields => [:title]
      end.results
      results.should == [@posts[1]]
    end
  end

  describe 'with field boost' do
    before :all do
      Sunspot.remove_all
      @posts = [:title, :body].map { |field| Post.new(field => 'rhinoceros') }
      Sunspot.index!(*@posts)
    end

    it 'should assign a higher score to the result matching the higher-boosted field' do
      search = Sunspot.search(Post) { keywords 'rhinoceros' }
      search.hits.map { |hit| hit.primary_key }.should ==
        @posts.map { |post| post.id.to_s }
      search.hits.first.score.should > search.hits.last.score
    end
  end

  describe 'with document boost' do
    before :all do
      Sunspot.remove_all
      @posts = [4.0, 2.0].map do |rating|
        Post.new(:title => 'Test', :ratings_average => rating)
      end
      Sunspot.index!(*@posts)
    end

    it 'should assign a higher score to the higher-boosted document' do
      search = Sunspot.search(Post) { keywords 'test' }
      search.hits.map { |hit| hit.primary_key }.should == 
        @posts.map { |post| post.id.to_s }
      search.hits.first.score.should > search.hits.last.score
    end
  end
end
