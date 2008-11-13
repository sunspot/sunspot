require File.join(File.dirname(__FILE__), 'test_helper')

class TestRetrieveSearch < Test::Unit::TestCase
  include RR::Adapters::TestUnit

  before do
    stub(Solr::Connection).new { connection } 
  end

  test 'should load search result' do
    post = Post.new
    stub_results(post)

    Sunspot.search(Post).results.should == [post]
  end

  test 'should load multiple search results in order' do
    post_1, post_2 = Post.new, Post.new
    stub_results(post_1, post_2)
    Sunspot.search(Post).results.should == [post_1, post_2]
    stub_results(post_2, post_1)
    Sunspot.search(Post).results.should == [post_2, post_1]
  end

  test 'should return search total as attribute of results if pagination is provided' do
    stub_results(Post.new, 4)
    Sunspot.search(Post, :page => 1).results.total_entries.should == 4
  end

  test 'should return vanilla array if pagination is provided but WillPaginate is not available' do
    stub_results(Post.new)
    without_class(WillPaginate) do
      Sunspot.search(Post, :page => 1).results.should_not respond_to(:total_entries)
    end
  end

  private

  def stub_results(*results)
    total_hits = if results.last.is_a?(Integer) then results.pop 
                 else results.length
                 end
    response = Object.new
    stub(response).hits { results.map { |result| { 'id' => "#{result.class.name} #{result.id}" }}}
    stub(response).total_hits { total_hits }
    stub(connection).query { response }
  end

  def connection
    @connection ||= Object.new
  end
end
