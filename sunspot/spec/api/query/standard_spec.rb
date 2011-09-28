require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'standard query', :type => :query do
  it_should_behave_like "scoped query"
  it_should_behave_like "query with advanced manipulation"
  it_should_behave_like "query with connective scope"
  it_should_behave_like "query with dynamic field support"
  it_should_behave_like "facetable query"
  it_should_behave_like "fulltext query"
  it_should_behave_like "query with highlighting support"
  it_should_behave_like "sortable query"
  it_should_behave_like "query with text field scoping"
  it_should_behave_like "geohash query"
  it_should_behave_like "spatial query"

  it 'adds a no-op query to :q parameter when no :q provided' do
    session.search Post do
      with :title, 'My Pet Post'
    end
    connection.should have_last_search_with(:q => '*:*')
  end

  private

  def search(*classes, &block)
    classes[0] ||= Post
    session.search(*classes, &block)
  end
end
