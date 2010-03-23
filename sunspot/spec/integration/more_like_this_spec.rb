describe 'more_like_this' do
  before :all do
    Sunspot.remove_all
    @posts = [
      Post.new(:title => 'Post123', :body => "one two three", :tags => %w(ruby sunspot rsolr)),
      Post.new(:title => 'Post456', :body => "four five six", :tags => %w(ruby solr lucene)),
      Post.new(:title => 'Post234', :body => "two three four", :tags => %w(python sqlalchemy)),
      Post.new(:title => 'Post345', :body => "three four five", :tags => %w(ruby sunspot mat)),
    ]
    Sunspot.index!(@posts)
  end

  it 'should return results' do
    Sunspot.more_like_this(@posts.first).results.should_not be_empty
  end

  it 'should return results for text fields' do
    Sunspot.more_like_this(@posts.first) do 
      fields :body
    end.results.should == @posts[2..3]
  end
end
