require File.expand_path('../spec_helper', File.dirname(__FILE__))

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
                         :body => 'Does the host\'s wind interpret the buffer, moron?')
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

    it 'matches multiple keywords on different fields using subqueries' do
      search = Sunspot.search(Post) do
        keywords 'moron', :fields => [:title]
        keywords 'wind',  :fields => [:body]
      end
      search.results.should == []

      search = Sunspot.search(Post) do
        keywords 'moron',   :fields => [:title]
        keywords 'buffer',  :fields => [:body]
      end
      search.results.should == [@posts[1]]
    end

    it 'matches multiple keywords with escaped characters' do
      search = Sunspot.search(Post) do
        keywords 'spirit',   :fields => [:title]
        keywords 'host\'s',  :fields => [:body]
      end
      search.results.should == [@posts[2]]
    end

    it 'matches multiple keywords with phrase-based search' do
      search = Sunspot.search(Post) do
        keywords 'spirit', :fields => [:title]
        keywords '"interpret the buffer"', :fields => [:body]
        keywords '"does the"', :fields => [:body]
      end
      search.results.should == [@posts[2]]
    end

    it 'matches multiple keywords different options' do
      search = Sunspot.search(Post) do
        keywords 'insufficient nonexistent', :fields => [:title], :minimum_match => 1
        keywords 'wind does', :fields => [:body], :minimum_match => 2
      end
      search.results.should == [@posts[0]]
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

  describe 'with search-time boost' do
    before :each do
      Sunspot.remove_all
      @comments = [
        Namespaced::Comment.new(:body => 'test text'),
        Namespaced::Comment.new(:author_name => 'test text')
      ]
      Sunspot.index!(@comments)
    end

    it 'assigns a higher score to documents in which all words appear in the phrase field' do
      hits = Sunspot.search(Namespaced::Comment) do
        keywords 'test text' do
          phrase_fields :body => 2.0
        end
      end.hits
      hits.first.instance.should == @comments.first
      hits.first.score.should > hits.last.score
    end

    it 'assigns a higher score to documents in which the search terms appear in a boosted field' do
      hits = Sunspot.search(Namespaced::Comment) do
        keywords 'test' do
          fields :body => 2.0, :author_name => 0.75
        end
      end.hits
      hits.first.instance.should == @comments.first
      hits.first.score.should > hits.last.score
    end

    it 'assigns a higher score to documents in which the search terms appear in a higher boosted phrase field' do
      hits = Sunspot.search(Namespaced::Comment) do
        keywords 'test text' do
          phrase_fields :body => 2.0, :author_name => 0.75
        end
      end.hits
      hits.first.instance.should == @comments.first
      hits.first.score.should > hits.last.score
    end
  end

  describe 'boost query' do
    before :all do
      Sunspot.remove_all
      Sunspot.index!(
        @posts = [
          Post.new(:title => 'Rhino', :featured => true),
          Post.new(:title => 'Rhino', :ratings_average => 3.3),
          Post.new(:title => 'Rhino')
        ]
      )
    end

    it 'should assign a higher score to the document matching the boost query' do
      search = Sunspot.search(Post) do |query|
        query.keywords('rhino') do
          boost(2.0) do
            with(:featured, true)
          end
        end
        query.without(@posts[1])
      end
      search.results.should == [@posts[0], @posts[2]]
      search.hits[0].score.should > search.hits[1].score
    end

    it 'should assign scores in order of multiple boost query match' do
      search = Sunspot.search(Post) do
        keywords 'rhino' do
          boost(2.0) { with(:featured, true) }
          boost(1.5) { with(:average_rating).greater_than(3.0) }
        end
      end
      search.results.should == @posts
      search.hits[0].score.should > search.hits[1].score
      search.hits[1].score.should > search.hits[2].score
    end
  end

  describe 'minimum match' do
    before do
      Sunspot.remove_all
      @posts = [
        Post.new(:title => 'Pepperoni Sausage Anchovies'),
        Post.new(:title => 'Pepperoni Tomatoes Mushrooms')
      ]
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        keywords 'pepperoni sausage extra cheese', :minimum_match => 2
      end
    end

    it 'should match documents that contain the minimum_match number of search terms' do
      @search.results.should include(@posts[0])
    end

    it 'should not match documents that do not contain the minimum_match number of search terms' do
      @search.results.should_not include(@posts[1])
    end
  end

  describe 'query phrase slop' do
    before do
      Sunspot.remove_all
      @posts = [
        Post.new(:title => 'One four'),
        Post.new(:title => 'One three four'),
        Post.new(:title => 'One two three four')
      ]
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        keywords '"one four"', :query_phrase_slop => 1
      end
    end

    it 'should match exact phrase' do
      @search.results.should include(@posts[0])
    end

    it 'should match phrase divided by query phrase slop terms' do
      @search.results.should include(@posts[1])
    end

    it 'should not match phrase divided by more than query phrase slop terms' do
      @search.results.should_not include(@posts[2])
    end
  end

  describe 'phrase field slop' do
    before do
      Sunspot.remove_all
      @comments = [
        Namespaced::Comment.new(:author_name => 'one four'),
        Namespaced::Comment.new(:body => 'one four'),
        Namespaced::Comment.new(:author_name => 'one three four'),
        Namespaced::Comment.new(:body => 'one three four'),
        Namespaced::Comment.new(:author_name => 'one two three four'),
        Namespaced::Comment.new(:body => 'one two three four')
      ]
      Sunspot.index!(@comments)
      @search = Sunspot.search(Namespaced::Comment) do
        keywords 'one four' do
          phrase_fields :author_name => 3.0
          phrase_slop 1
        end
      end
      @sorted_hits = @search.hits.sort_by { |hit| @comments.index(hit.instance) }
    end

    it 'should give phrase field boost to exact match' do
      @sorted_hits[0].score.should > @sorted_hits[1].score
    end

    it 'should give phrase field boost to match within slop' do
      @sorted_hits[2].score.should > @sorted_hits[3].score
    end

    it 'should not give phrase field boost to match beyond slop' do
      @sorted_hits[4].score.should == @sorted_hits[5].score
    end
  end

  describe 'with function queries' do
    before :each do
      Sunspot.remove_all
    end

    after :each do
      @search.results.should == @posts
      @search.hits.first.score.should > @search.hits.last.score
    end

    it 'boosts via function query with float' do
      @posts = [Post.new(:title => 'test', :ratings_average => 4.0),
                Post.new(:title => 'test', :ratings_average => 2.0)]
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        keywords('test') do
          boost function { :average_rating }
        end
      end
    end

    it 'boosts via function query with date' do
      @posts = [Post.new(:title => 'test', :published_at => Time.now),
                Post.new(:title => 'test', :published_at => Time.now - 60*60*24*31*6)] # roughly six months ago
      Sunspot.index!(@posts)
      @search = Sunspot.search(Post) do
        keywords('test') do
          boost function { recip(ms(Time.now, :published_at), 3.16e-11, 1, 1) }
        end
      end
    end
  end
end
