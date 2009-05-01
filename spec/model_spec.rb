require File.join(File.dirname(__FILE__), 'spec_helper')

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
      @posts = Array.new(10) { Post.create! }.each { |post| Sunspot.index(post) }
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
      Array.new(10) { Post.create! }.each { |post| Sunspot.index(post) }
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
      Blog.should_not be_searchable
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
end
