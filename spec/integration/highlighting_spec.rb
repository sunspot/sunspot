describe 'keyword highlighting' do
  before :all do
    @posts = []
    @posts << Post.new(:title => 'The quick brown fox jumped over the lazy dog', :body => 'And the fox laughed')
    @posts << Post.new(:title => 'Pellentesque ac dolor', :body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit', :blog_id => 1)
    Sunspot.index!(*@posts)
    @search_result = Sunspot.search(Post){ keywords 'fox' }
  end
  
  it 'should include highlights in the results' do
    @search_result.hits.first.highlights.length.should eql(2)
  end
  
  it 'should include highlights for all relevant fields' do
    @search_result.hits.first.highlights(:title_text).highlight.should eql('The quick brown @@@hl@@@fox@@@endhl@@@ jumped over the lazy dog')
    @search_result.hits.first.highlights(:body_text).highlight.should eql('And the @@@hl@@@fox@@@endhl@@@ laughed')
  end
  
  it 'should highlight the search term' do
    @search_result.hits.first.highlights.first.highlight.should eql('The quick brown @@@hl@@@fox@@@endhl@@@ jumped over the lazy dog')
  end
  
  it 'should be empty for non-keyword searches' do
    search_result = Sunspot.search(Post){ with :blog_id, 1 }
    search_result.hits.first.highlights.should eql([])
  end
  
  it 'should be able to render with custom format' do
    @search_result.hits.first.highlights.first.format{|str| "<strong>#{str}</strong>"}.should eql('The quick brown <strong>fox</strong> jumped over the lazy dog')
  end
  
  it 'should use <em> when format is called without a block' do
    @search_result.hits.first.highlights.first.format.should eql('The quick brown <em>fox</em> jumped over the lazy dog')
  end
end