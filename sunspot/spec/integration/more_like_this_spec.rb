describe 'more_like_this' do
  before :all do
    Sunspot.remove_all
    @posts = [
      Post.new(:body => "one two three", :tags => %w(ruby sunspot rsolr)),
      Post.new(:body => "four five six", :tags => %w(ruby solr lucene)),
      Post.new(:body => "two three four", :tags => %w(python sqlalchemy)),
      Post.new(:body => "three four five", :tags => %w(ruby sunspot mat)),
      Post.new(:body => "six seven eight", :tags => %w(bogus airplane))
    ]
    Sunspot.index!(@posts)
  end

  it 'should return results for all MLT fields' do
    Sunspot.more_like_this(@posts.first).results.to_set.should == @posts[1..3].to_set
  end

  it 'should return results for specified text field' do
    Sunspot.more_like_this(@posts.first) do 
      fields :body
    end.results.to_set.should == @posts[2..3].to_set
  end
end
