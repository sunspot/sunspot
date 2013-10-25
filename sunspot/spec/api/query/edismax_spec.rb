require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'extended dismax query', :type => :query do
  let(:def_type) {'edismax'}
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

  def search(*classes, &block)
    classes[0] ||= Post
    session.search(*classes) do |search|
      instance_variables.each do |ivar|
        ival = instance_variable_get(ivar)
        search.instance_variable_set(ivar,ival)
      end
      search.parser :edismax
      search.instance_eval &block if block_given?
    end
  end

end