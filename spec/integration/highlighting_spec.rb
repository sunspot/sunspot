describe 'keyword highlighting' do
  before :all do
    @posts = []
    @posts << Post.new(:body => 'And the fox laughed')
    @posts << Post.new(:body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit', :blog_id => 1)
    Sunspot.index!(*@posts)
    @search_result = Sunspot.search(Post) { keywords 'fox', :highlight => true }
  end
  
  it 'should include highlights in the results' do
    @search_result.hits.first.highlights.length.should == 1
  end
  
  it 'should return formatted highlight fragments' do
    @search_result.hits.first.highlights(:body).first.format.should == 'And the <em>fox</em> laughed'
  end
  
  it 'should be empty for non-keyword searches' do
    search_result = Sunspot.search(Post){ with :blog_id, 1 }
    search_result.hits.first.highlights.should be_empty
  end
end
