describe 'keyword highlighting' do
  before :all do
    @posts = []
    @posts << Post.new(:title => 'The quick brown fox jumped over the lazy dog', :body => 'And tripped')
    @posts << Post.new(:title => 'Pellentesque ac dolor', :body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit', :blog_id => 1)
    Sunspot.index!(*@posts)
  end
  
  it 'should include highlights in the results' do
    search_result = Sunspot.search(Post){ keywords 'fox' }
    search_result.highlights.length.should eql(1)
  end
  
  it 'should highlight the search term' do
    search_result = Sunspot.search(Post){ keywords 'fox' }
    search_result.highlights.first.highlight.should eql('The quick brown <em>fox</em> jumped over the lazy dog')
  end
  
  it 'should be nil for non-keyword searches' do
    search_result = Sunspot.search(Post){ with :blog_id, 1 }
    search_result.highlights.first.highlight.should eql(nil)
  end
  
  it 'should not fail when there are no search results' do
    search_result = Sunspot.search(Post){ keywords 'no results here' }
    lambda{search_result.highlights}.should_not raise_error
  end
end