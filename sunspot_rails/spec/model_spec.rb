require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'ActiveRecord mixin' do
  describe 'index()' do
    before :each do
      @post = Post.create!
      @post.index
    end

    it 'should not commit the model' do
      Post.search.results.should be_empty
    end

    it 'should index the model' do
      Sunspot.commit
      Post.search.results.should == [@post]
    end

    it "should not blow up if there's a default scope specifying order" do
      posts = Array.new(2) { |j| PostWithDefaultScope.create! :title => (10-j).to_s }
      lambda { PostWithDefaultScope.index(:batch_size => 1) }.should_not raise_error
    end
  end

  describe 'single table inheritence' do
    before :each do
      @post = PhotoPost.create!
    end

    it 'should not break auto-indexing' do
      @post.title = 'Title'
      lambda { @post.save! }.should_not raise_error
    end
  end

  describe 'index!()' do
    before :each do
      @post = Post.create!
      @post.index!
    end

    it 'should immediately index and commit' do
      Post.search.results.should == [@post]
    end
  end

  describe 'remove_from_index()' do
    before :each do
      @post = Post.create!
      @post.index!
      @post.remove_from_index
    end

    it 'should not commit immediately' do
      Post.search.results.should == [@post]
    end

    it 'should remove the model from the index' do
      Sunspot.commit
      Post.search.results.should be_empty
    end
  end

  describe 'remove_from_index!()' do
    before :each do
      @post = Post.create!
      @post.index!
      @post.remove_from_index!
    end

    it 'should immediately remove the model and commit' do
      Post.search.results.should be_empty
    end
  end

  describe 'remove_all_from_index' do
    before :each do
      @posts = Array.new(2) { Post.create! }.each { |post| Sunspot.index(post) }
      Sunspot.commit
      Post.remove_all_from_index
    end

    it 'should not commit immediately' do
      Post.search.results.to_set.should == @posts.to_set
    end

    it 'should remove all instances from the index' do
      Sunspot.commit
      Post.search.results.should be_empty
    end
  end

  describe 'remove_all_from_index!' do
    before :each do
      Array.new(2) { Post.create! }.each { |post| Sunspot.index(post) }
      Sunspot.commit
      Post.remove_all_from_index!
    end

    it 'should remove all instances from the index and commit immediately' do
      Post.search.results.should be_empty
    end
  end

  describe 'search()' do
    before :each do
      @post = Post.create!(:title => 'Test Post')
      @post.index!
    end

    it 'should return results specified by search' do
      Post.search do
        with :title, 'Test Post'
      end.results.should == [@post]
    end

    it 'should not return results excluded by search' do
      Post.search do
        with :title, 'Bogus Post'
      end.results.should be_empty
    end
    
    it 'should use the include option on the data accessor when specified' do
      Post.should_receive(:all).with(hash_including(:include => [:blog])).and_return([@post])
      Post.search do
        with :title, 'Test Post'
        data_accessor_for(Post).include = [:blog]
      end.results.should == [@post]
    end

    it 'should pass :include option from search call to data accessor' do
      Post.should_receive(:all).with(hash_including(:include => [:blog])).and_return([@post])
      Post.search(:include => [:blog]) do
        with :title, 'Test Post'
      end.results.should == [@post]
    end
    
    it 'should use the select option from search call to data accessor' do
      Post.should_receive(:all).with(hash_including(:select => 'title, published_at')).and_return([@post])
      Post.search(:select => 'title, published_at') do
        with :title, 'Test Post'
      end.results.should == [@post]
    end

    it 'should not allow bogus options to search' do
      lambda { Post.search(:bogus => :option) }.should raise_error(ArgumentError)
    end
    
    it 'should use the select option on the data accessor when specified' do
      Post.should_receive(:all).with(hash_including(:select => 'title, published_at')).and_return([@post])
      Post.search do
        with :title, 'Test Post'
        data_accessor_for(Post).select = [:title, :published_at]
      end.results.should == [@post]
    end
    
    it 'should not use the select option on the data accessor when not specified' do
      Post.should_receive(:all).with(hash_not_including(:select)).and_return([@post])
      Post.search do
        with :title, 'Test Post'
      end.results.should == [@post]
    end

    it 'should gracefully handle nonexistent records' do
      post2 = Post.create!(:title => 'Test Post')
      post2.index!
      post2.destroy
      Post.search do
        with :title, 'Test Post'
      end.results.should == [@post]
    end

    it 'should use an ActiveRecord object for coordinates' do
      post = Post.new(:title => 'Test Post')
      post.location = Location.create!(:lat => 40.0, :lng => -70.0)
      post.save
      post.index!
      Post.search { with(:location).near(40.0, -70.0) }.results.should == [post]
    end

  end

  describe 'search_ids()' do
    before :each do
      @posts = Array.new(2) { Post.create! }.each { |post| post.index }
      Sunspot.commit
    end

    it 'should return IDs' do
      Post.search_ids.to_set.should == @posts.map { |post| post.id }.to_set
    end
  end
  
  describe 'searchable?()' do
    it 'should not be true for models that have not been configured for search' do
      Location.should_not be_searchable
    end

    it 'should be true for models that have been configured for search' do
      Post.should be_searchable
    end
  end

  describe 'index_orphans()' do
    before :each do
      @posts = Array.new(2) { Post.create }.each { |post| post.index }
      Sunspot.commit
      @posts.first.destroy
    end

    it 'should return IDs of objects that are in the index but not the database' do
      Post.index_orphans.should == [@posts.first.id]
    end
  end

  describe 'clean_index_orphans()' do
    before :each do
      @posts = Array.new(2) { Post.create }.each { |post| post.index }
      Sunspot.commit
      @posts.first.destroy
    end

    it 'should remove orphans from the index' do
      Post.clean_index_orphans
      Sunspot.commit
      Post.search.results.should == [@posts.last]
    end
  end

  describe 'reindex()' do
    before :each do
      @posts = Array.new(2) { Post.create }
    end

    it 'should index all instances' do
      Post.reindex(:batch_size => nil)
      Sunspot.commit
      Post.search.results.to_set.should == @posts.to_set
    end

    it 'should remove all currently indexed instances' do
      old_post = Post.create!
      old_post.index!
      old_post.destroy
      Post.reindex
      Sunspot.commit
      Post.search.results.to_set.should == @posts.to_set
    end
    
  end

  describe 'reindex() with real data' do
    before :each do
      @posts = Array.new(2) { Post.create }
    end

    it 'should index all instances' do
      Post.reindex(:batch_size => nil)
      Sunspot.commit
      Post.search.results.to_set.should == @posts.to_set
    end

    it 'should remove all currently indexed instances' do
      old_post = Post.create!
      old_post.index!
      old_post.destroy
      Post.reindex
      Sunspot.commit
      Post.search.results.to_set.should == @posts.to_set
    end
    
    describe "using batch sizes" do
      it 'should index with a specified batch size' do
        Post.reindex(:batch_size => 1)
        Sunspot.commit
        Post.search.results.to_set.should == @posts.to_set
      end
    end
  end


  
  describe "reindex()" do
  
    before(:each) do
      @posts = Array.new(2) { Post.create }
    end

    describe "when not using batches" do
      
      it "should select all if the batch_size is nil" do
        Post.should_receive(:all).with(:include => []).and_return([])
        Post.reindex(:batch_size => nil)
      end

      it "should search for models with includes" do
        Post.should_receive(:all).with(:include => :author).and_return([])
        Post.reindex(:batch_size => nil, :include => :author)
      end

      describe ':if constraints' do
        before do
          Post.sunspot_options[:if] = proc { |model| model.id != @posts.first.id }
        end

        after do
          Post.sunspot_options[:if] = nil
        end

        it 'should only index those models where :if constraints pass' do
          Post.reindex(:batch_size => nil)

          Post.search.results.should_not include(@posts.first)
        end
      end
    
    end

    describe "when using batches" do
      it "should commit after indexing each batch" do
        Sunspot.should_receive(:commit).twice
        Post.reindex(:batch_size => 1)
      end

      it "should commit after indexing everything" do
        Sunspot.should_receive(:commit).once
        Post.reindex(:batch_commit => false)
      end

      describe ':if constraints' do
        before do
          Post.sunspot_options[:if] = proc { |model| model.id != @posts.first.id }
        end

        after do
          Post.sunspot_options[:if] = nil
        end

        it 'should only index those models where :if constraints pass' do
          Post.reindex(:batch_size => 50)

          Post.search.results.should_not include(@posts.first)
        end
      end
    end
  end
  
  describe "more_like_this()" do
    before(:each) do
      @posts = [
        Post.create!(:title => 'Post123', :body => "one two three"),
        Post.create!(:title => 'Post345', :body => "three four five"),
        Post.create!(:title => 'Post456', :body => "four five six"),
        Post.create!(:title => 'Post234', :body => "two three four"),
      ]
      @posts_with_auto = [
        PostWithAuto.create!(:body => "one two three"),
        PostWithAuto.create!(:body => "four five six")
      ]
      @posts.each { |p| p.index! }
    end

    it "should return results" do
      @posts.first.more_like_this.results.should == [@posts[3], @posts[1]]
    end

    it "should return results for specified classes" do
      @posts.first.more_like_this(Post, PostWithAuto).results.to_set.should ==
        Set[@posts_with_auto[0], @posts[1], @posts[3]]
    end
  end

  describe 'more_like_this_ids()' do
    before :each do
      @posts = [
        Post.create!(:title => 'Post123', :body => "one two three"),
        Post.create!(:title => 'Post345', :body => "three four five"),
        Post.create!(:title => 'Post456', :body => "four five six"),
        Post.create!(:title => 'Post234', :body => "two three four"),
      ]
      @posts.each { |p| p.index! }
    end

    it 'should return IDs' do
      @posts.first.more_like_this_ids.to_set.should == [@posts[3], @posts[1]].map { |post| post.id }.to_set
    end
  end

  describe ':if constraint' do
    subject do
      PostWithAuto.new(:title => 'Post123')
    end

    after do
      subject.class.sunspot_options[:if] = nil
    end

    context 'Symbol' do
      context 'constraint returns true' do
        # searchable :if => :returns_true
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:if] = :returns_true
        end

        it_should_behave_like 'indexed after save'
      end

      context 'constraint returns false' do
        # searchable :if => :returns_false
        before do
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:if] = :returns_false
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    context 'String' do
      context 'constraint returns true' do
        # searchable :if => 'returns_true'
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:if] = 'returns_true'
        end

        it_should_behave_like 'indexed after save'
      end

      context 'constraint returns false' do
        # searchable :if => 'returns_false'
        before do
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:if] = 'returns_false'
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    context 'Proc' do
      context 'constraint returns true' do
        # searchable :if => proc { true }
        before do
          subject.class.sunspot_options[:if] = proc { true }
        end

        it_should_behave_like 'indexed after save'
      end

      context 'constraint returns false' do
        # searchable :if => proc { false }
        before do
          subject.class.sunspot_options[:if] = proc { false }
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    context 'Array' do
      context 'all constraints returns true' do
        # searchable :if => [:returns_true_1, :returns_true_2]
        before do
          subject.should_receive(:returns_true_1).and_return(true)
          subject.should_receive(:returns_true_2).and_return(true)
          subject.class.sunspot_options[:if] = [:returns_true_1, 'returns_true_2']
        end

        it_should_behave_like 'indexed after save'
      end

      context 'one constraint returns false' do
        # searchable :if => [:returns_true, :returns_false]
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:if] = [:returns_true, 'returns_false']
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    it 'removes the model from the index if the constraint does not match' do
      subject.save!
      Sunspot.commit
      subject.class.search.results.should include(subject)

      subject.class.sunspot_options[:if] = proc { false }
      subject.save!
      Sunspot.commit
      subject.class.search.results.should_not include(subject)
    end
  end

  describe ':unless constraint' do
    subject do
      PostWithAuto.new(:title => 'Post123')
    end

    after do
      subject.class.sunspot_options[:unless] = nil
    end

    context 'Symbol' do
      context 'constraint returns true' do
        # searchable :unless => :returns_true
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:unless] = :returns_true
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'constraint returns false' do
        # searchable :unless => :returns_false
        before do
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:unless] = :returns_false
        end

        it_should_behave_like 'indexed after save'
      end
    end

    context 'String' do
      context 'constraint returns true' do
        # searchable :unless => 'returns_true'
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:unless] = 'returns_true'
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'constraint returns false' do
        # searchable :unless => 'returns_false'
        before do
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:unless] = 'returns_false'
        end

        it_should_behave_like 'indexed after save'
      end
    end

    context 'Proc' do
      context 'constraint returns true' do
        # searchable :unless => proc { true }
        before do
          subject.class.sunspot_options[:unless] = proc { |model| model == subject } # true
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'constraint returns false' do
        # searchable :unless => proc { false }
        before do
          subject.class.sunspot_options[:unless] = proc { false }
        end

        it_should_behave_like 'indexed after save'
      end
    end

    context 'Array' do
      context 'all constraints returns true' do
        # searchable :unless => [:returns_true_1, :returns_true_2]
        before do
          subject.should_receive(:returns_true_1).and_return(true)
          subject.should_receive(:returns_true_2).and_return(true)
          subject.class.sunspot_options[:unless] = [:returns_true_1, 'returns_true_2']
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'one constraint returns false' do
        # searchable :unless => [:returns_true, :returns_false]
        before do
          subject.should_receive(:returns_true).and_return(true)
          subject.should_receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:unless] = [:returns_true, 'returns_false']
        end

        it_should_behave_like 'indexed after save'
      end
    end
  end
end
