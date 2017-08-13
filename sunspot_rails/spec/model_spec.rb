require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'ActiveRecord mixin' do
  describe 'index()' do
    before :each do
      @post = Post.create!
      @post.index
    end

    it 'should not commit the model' do
      expect(Post.search.results).to be_empty
    end

    it 'should index the model' do
      Sunspot.commit
      expect(Post.search.results).to eq([@post])
    end

    it "should not blow up if there's a default scope specifying order" do
      posts = Array.new(2) { |j| PostWithDefaultScope.create! :title => (10-j).to_s }
      expect { PostWithDefaultScope.index(:batch_size => 1) }.not_to raise_error
    end
  end

  describe 'single table inheritence' do
    before :each do
      @post = PhotoPost.create!
    end

    it 'should not break auto-indexing' do
      @post.title = 'Title'
      expect { @post.save! }.not_to raise_error
    end
  end

  describe 'index!()' do
    before :each do
      @post = Post.create!
      @post.index!
    end

    it 'should immediately index and commit' do
      expect(Post.search.results).to eq([@post])
    end
  end

  describe 'remove_from_index()' do
    before :each do
      @post = Post.create!
      @post.index!
      @post.remove_from_index
    end

    it 'should not commit immediately' do
      expect(Post.search.results).to eq([@post])
    end

    it 'should remove the model from the index' do
      Sunspot.commit
      expect(Post.search.results).to be_empty
    end
  end

  describe 'remove_from_index!()' do
    before :each do
      @post = Post.create!
      @post.index!
      @post.remove_from_index!
    end

    it 'should immediately remove the model and commit' do
      expect(Post.search.results).to be_empty
    end
  end

  describe 'remove_all_from_index' do
    before :each do
      @posts = Array.new(2) { Post.create! }.each { |post| Sunspot.index(post) }
      Sunspot.commit
      Post.remove_all_from_index
    end

    it 'should not commit immediately' do
      expect(Post.search.results.to_set).to eq(@posts.to_set)
    end

    it 'should remove all instances from the index' do
      Sunspot.commit
      expect(Post.search.results).to be_empty
    end
  end

  describe 'remove_all_from_index!' do
    before :each do
      Array.new(2) { Post.create! }.each { |post| Sunspot.index(post) }
      Sunspot.commit
      Post.remove_all_from_index!
    end

    it 'should remove all instances from the index and commit immediately' do
      expect(Post.search.results).to be_empty
    end
  end

  describe 'search()' do
    before :each do
      @post = Post.create!(:title => 'Test Post')
      @post.index!
    end

    it 'should return results specified by search' do
      expect(Post.search do
        with :title, 'Test Post'
      end.results).to eq([@post])
    end

    it 'should not return results excluded by search' do
      expect(Post.search do
        with :title, 'Bogus Post'
      end.results).to be_empty
    end

    it 'should not allow bogus options to search' do
      expect { Post.search(:bogus => :option) }.to raise_error(ArgumentError)
    end

    it 'should pass :include option from search call to data accessor' do
      expect(Post.search(:include => [:location]) do
        with :title, 'Test Post'
      end.data_accessor_for(Post).include).to eq([:location])
    end
    
    it 'should use the include option on the data accessor when specified' do
      @post.update_attribute(:location, Location.create)
      post = Post.search do
        with :title, 'Test Post'
        data_accessor_for(Post).include = [:location]
      end.results.first

      expect(Rails.version >= '3.1' ? post.association(:location).loaded? : post.loaded_location?).to be_truthy # Rails 3.1 removed "loaded_#{association}" method
    end
    
    it 'should use the select option from search call to data accessor' do
      expect(Post.search(:select => 'id, title, body') do
        with :title, 'Test Post'
      end.data_accessor_for(Post).select).to eq('id, title, body')
    end
    
    it 'should use the select option on the data accessor when specified' do
      expect(Post.search do
        with :title, 'Test Post'
        data_accessor_for(Post).select = 'id, title, body'
      end.results.first.attribute_names.sort).to eq(['body', 'id', 'title'])
    end
    
    it 'should not use the select option on the data accessor when not specified' do
      expect(Post.search do
        with :title, 'Test Post'
      end.results.first.attribute_names).to eq(Post.first.attribute_names)
    end

    it 'should accept an array as a select option' do
      expect(Post.search(:select => ['id', 'title', 'body']) do
        with :title, 'Test Post'
      end.results.first.attribute_names.sort).to eq(['body', 'id', 'title'])
    end

    it 'should use the scoped option from search call to data accessor' do
      expect(Post.search(:scopes => [:includes_location]) do
        with :title, 'Test Post'
      end.data_accessor_for(Post).scopes).to eq([:includes_location])
    end

    it 'should use the scopes option on the data accessor when specified' do
      @post.update_attribute(:location, Location.create)
      post = Post.search do
        with :title, 'Test Post'
        data_accessor_for(Post).scopes = [:includes_location]
      end.results.first

      expect(Rails.version >= '3.1' ? post.association(:location).loaded? : post.loaded_location?).to be_truthy # Rails 3.1 removed "loaded_#{association}" method
    end

    it 'should gracefully handle nonexistent records' do
      post2 = Post.create!(:title => 'Test Post')
      post2.index!
      post2.destroy
      expect(Post.search do
        with :title, 'Test Post'
      end.results).to eq([@post])
    end

    it 'should use an ActiveRecord object for coordinates' do
      post = Post.new(:title => 'Test Post')
      post.location = Location.create!(:lat => 40.0, :lng => -70.0)
      post.save
      post.index!
      expect(Post.search { with(:location).near(40.0, -70.0) }.results).to eq([post])
    end

  end

  describe 'search_ids()' do
    before :each do
      @posts = Array.new(2) { Post.create! }.each { |post| post.index }
      Sunspot.commit
    end

    it 'should return IDs' do
      expect(Post.search_ids.to_set).to eq(@posts.map { |post| post.id }.to_set)
    end
  end
  
  describe 'searchable?()' do
    it 'should not be true for models that have not been configured for search' do
      expect(Location).not_to be_searchable
    end

    it 'should be true for models that have been configured for search' do
      expect(Post).to be_searchable
    end
  end

  describe 'index_orphans()' do
    before :each do
      @posts = Array.new(2) { Post.create }.each { |post| post.index }
      Sunspot.commit
      @posts.first.destroy
    end

    it 'should return IDs of objects that are in the index but not the database' do
      expect(Post.index_orphans).to eq([@posts.first.id])
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
      expect(Post.search.results).to eq([@posts.last])
    end
  end

  describe 'reindex()' do
    before :each do
      @posts = Array.new(2) { Post.create }
    end

    it 'should index all instances' do
      Post.reindex(:batch_size => nil)
      Sunspot.commit
      expect(Post.search.results.to_set).to eq(@posts.to_set)
    end

    it 'should remove all currently indexed instances' do
      old_post = Post.create!
      old_post.index!
      old_post.destroy
      Post.reindex
      Sunspot.commit
      expect(Post.search.results.to_set).to eq(@posts.to_set)
    end
    
  end

  describe 'reindex() with real data' do
    before :each do
      @posts = Array.new(2) { Post.create }
    end

    it 'should index all instances' do
      Post.reindex(:batch_size => nil)
      Sunspot.commit
      expect(Post.search.results.to_set).to eq(@posts.to_set)
    end

    it 'should remove all currently indexed instances' do
      old_post = Post.create!
      old_post.index!
      old_post.destroy
      Post.reindex
      Sunspot.commit
      expect(Post.search.results.to_set).to eq(@posts.to_set)
    end
    
    describe "using batch sizes" do
      it 'should index with a specified batch size' do
        Post.reindex(:batch_size => 1)
        Sunspot.commit
        expect(Post.search.results.to_set).to eq(@posts.to_set)
      end
    end
  end


  
  describe "reindex()" do
  
    before(:each) do
      @posts = Array.new(2) { Post.create }
    end

    it "should use batches if the batch_size is specified" do
      expect_any_instance_of(relation(Post).class).to receive(:find_in_batches)
      Post.reindex(:batch_size => 50)
    end

    it "should select all if the batch_size isn't greater than 0" do
      expect_any_instance_of(relation(Post).class).not_to receive(:find_in_batches)
      Post.reindex(:batch_size => nil)
      Post.reindex(:batch_size => 0)
    end

    describe "when not using batches" do
      it "should search for models with includes" do
        expect(Post).to receive(:includes).with(:author).and_return(relation(Post))
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

          expect(Post.search.results).not_to include(@posts.first)
        end
      end
    
    end

    describe "when using batches" do
      it "should commit after indexing each batch" do
        expect(Sunspot).to receive(:commit).twice
        Post.reindex(:batch_size => 1)
      end

      it "should commit after indexing everything" do
        expect(Sunspot).to receive(:commit).once
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

          expect(Post.search.results).not_to include(@posts.first)
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
      expect(@posts.first.more_like_this.results).to eq([@posts[3], @posts[1]])
    end

    it "should return results for specified classes" do
      expect(@posts.first.more_like_this(Post, PostWithAuto).results.to_set).to eq(
        Set[@posts_with_auto[0], @posts[1], @posts[3]]
      )
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
      expect(@posts.first.more_like_this_ids.to_set).to eq([@posts[3], @posts[1]].map { |post| post.id }.to_set)
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
          expect(subject).to receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:if] = :returns_true
        end

        it_should_behave_like 'indexed after save'
      end

      context 'constraint returns false' do
        # searchable :if => :returns_false
        before do
          expect(subject).to receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:if] = :returns_false
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    context 'String' do
      context 'constraint returns true' do
        # searchable :if => 'returns_true'
        before do
          expect(subject).to receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:if] = 'returns_true'
        end

        it_should_behave_like 'indexed after save'
      end

      context 'constraint returns false' do
        # searchable :if => 'returns_false'
        before do
          expect(subject).to receive(:returns_false).and_return(false)
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
          expect(subject).to receive(:returns_true_1).and_return(true)
          expect(subject).to receive(:returns_true_2).and_return(true)
          subject.class.sunspot_options[:if] = [:returns_true_1, 'returns_true_2']
        end

        it_should_behave_like 'indexed after save'
      end

      context 'one constraint returns false' do
        # searchable :if => [:returns_true, :returns_false]
        before do
          expect(subject).to receive(:returns_true).and_return(true)
          expect(subject).to receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:if] = [:returns_true, 'returns_false']
        end

        it_should_behave_like 'not indexed after save'
      end
    end

    it 'removes the model from the index if the constraint does not match' do
      subject.save!
      Sunspot.commit
      expect(subject.class.search.results).to include(subject)

      subject.class.sunspot_options[:if] = proc { false }
      subject.save!
      Sunspot.commit
      expect(subject.class.search.results).not_to include(subject)
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
          expect(subject).to receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:unless] = :returns_true
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'constraint returns false' do
        # searchable :unless => :returns_false
        before do
          expect(subject).to receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:unless] = :returns_false
        end

        it_should_behave_like 'indexed after save'
      end
    end

    context 'String' do
      context 'constraint returns true' do
        # searchable :unless => 'returns_true'
        before do
          expect(subject).to receive(:returns_true).and_return(true)
          subject.class.sunspot_options[:unless] = 'returns_true'
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'constraint returns false' do
        # searchable :unless => 'returns_false'
        before do
          expect(subject).to receive(:returns_false).and_return(false)
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
          expect(subject).to receive(:returns_true_1).and_return(true)
          expect(subject).to receive(:returns_true_2).and_return(true)
          subject.class.sunspot_options[:unless] = [:returns_true_1, 'returns_true_2']
        end

        it_should_behave_like 'not indexed after save'
      end

      context 'one constraint returns false' do
        # searchable :unless => [:returns_true, :returns_false]
        before do
          expect(subject).to receive(:returns_true).and_return(true)
          expect(subject).to receive(:returns_false).and_return(false)
          subject.class.sunspot_options[:unless] = [:returns_true, 'returns_false']
        end

        it_should_behave_like 'indexed after save'
      end
    end
  end
end
