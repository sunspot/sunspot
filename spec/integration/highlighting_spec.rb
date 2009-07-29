describe 'keyword highlighting' do
  before :all do
    @posts = []
    @posts << Post.new(:title => 'The quick brown fox jumped over the lazy dog', :body => 'And the fox laughed')
    @posts << Post.new(:title => 'Pellentesque ac dolor', :body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit', :blog_id => 1)
    Sunspot.index!(*@posts)
  end
  
  it 'should include highlights in the results' do
    search_result = Sunspot.search(Post){ keywords 'fox' }
    search_result.hits.first.highlights.length.should eql(2)
  end
  
  it 'should include highlights for all relevant fields' do
    search_result = Sunspot.search(Post){ keywords 'fox' }
    search_result.hits.first.highlights(:title_text).highlight.should eql('The quick brown <em>fox</em> jumped over the lazy dog')
    search_result.hits.first.highlights(:body_text).highlight.should eql('And the <em>fox</em> laughed')
  end
  
  it 'should highlight the search term' do
    search_result = Sunspot.search(Post){ keywords 'fox' }
    search_result.hits.first.highlights.first.highlight.should eql('The quick brown <em>fox</em> jumped over the lazy dog')
  end
  
  it 'should be empty for non-keyword searches' do
    search_result = Sunspot.search(Post){ with :blog_id, 1 }
    search_result.hits.first.highlights.should eql([])
  end
end