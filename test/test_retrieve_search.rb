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

  private

  def stub_results(*results)
    response = Object.new
    stub(response).hits { results.map { |result| { 'id' => "#{result.class.name} #{result.id}" }}}
    stub(connection).query { response }
  end

  def connection
    @connection ||= Object.new
  end
end
