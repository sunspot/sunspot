require File.expand_path('../spec_helper', File.dirname(__FILE__))

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
    expect(Sunspot.more_like_this(@posts.first).results.to_set).to eq(@posts[1..3].to_set)
  end

  it 'should return results for specified text field' do
    expect(Sunspot.more_like_this(@posts.first) do 
      fields :body
    end.results.to_set).to eq(@posts[2..3].to_set)
  end

  it 'should return empty result set if no results' do
    expect(Sunspot.more_like_this(@posts.last) do
      with(:title, 'bogus')
    end.results).to eq([])
  end

  describe 'when non-indexed object searched' do
    before(:each) { @mlt = Sunspot.more_like_this(Post.new) }

    it 'should return empty result set' do
      expect(@mlt.results).to eq([])
    end

    it 'shoult return a total of 0' do
      expect(@mlt.total).to eq(0)
    end
  end
end
