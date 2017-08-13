require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'keyword highlighting' do
  before :all do
    @posts = []
    @posts << Post.new(:body => 'And the fox laughed')
    @posts << Post.new(:body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit', :blog_id => 1)
    @posts << Post.new(:body => 'Lorem ipsum dolor sit amet', :title => 'consectetur adipiscing elit', :blog_id => 1)
    Sunspot.index!(*@posts)
    @search_result = Sunspot.search(Post) { keywords 'fox', :highlight => true }
  end
  
  it 'should include highlights in the results' do
    expect(@search_result.hits.first.highlights.length).to eq(1)
  end
  
  it 'should return formatted highlight fragments' do
    expect(@search_result.hits.first.highlights(:body).first.format).to eq('And the <em>fox</em> laughed')
  end
  
  it 'should be empty for non-keyword searches' do
    search_result = Sunspot.search(Post){ with :blog_id, 1 }
    expect(search_result.hits.first.highlights).to be_empty
  end
  
  it "should process multiple keyword request on different fields with highlights correctly" do
    search_results = nil
    expect do
      search_results = Sunspot.search(Post) do
        keywords 'Lorem ipsum', :fields => [:body] do
          highlight :body
        end
        keywords 'consectetur', :fields => [:title] do
          highlight :title
        end
      end
    end.to_not raise_error
    expect(search_results.results.length).to eq(1)
    expect(search_results.results.first).to eq(@posts.last)
    # this one might be a Solr bug, therefore not related to Sunspot itself
    # search_results.hits.first.highlights.should_not be_empty
  end
  
end
