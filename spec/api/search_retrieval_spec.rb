require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'retrieving search' do
  it 'should load search result' do
    post = Post.new
    stub_results(post)
    session.search(Post).results.should == [post]
  end

  it 'should load multiple search results in order' do
    post_1, post_2 = Post.new, Post.new
    stub_results(post_1, post_2)
    session.search(Post).results.should == [post_1, post_2]
    stub_results(post_2, post_1)
    session.search(Post).results.should == [post_2, post_1]
  end

  it 'should return search total as attribute of results if pagination is provided' do
    stub_results(Post.new, 4)
    session.search(Post, :page => 1).results.total_entries.should == 4
  end

  it 'should return vanilla array if pagination is provided but WillPaginate is not available' do
    stub_results(Post.new)
    without_class(WillPaginate) do
      session.search(Post, :page => 1).results.should_not respond_to(:total_entries)
    end
  end

  it 'should return total' do
    stub_results(Post.new, Post.new, 4)
    session.search(Post, :page => 1).total.should == 4
  end

  private

  def stub_results(*results)
    total_hits = if results.last.is_a?(Integer) then results.pop 
                 else results.length
                 end
    response = mock('response')
    response.stub!(:hits).and_return(results.map { |result| { 'id' => "#{result.class.name} #{result.id}" }})
    response.stub!(:total_hits).and_return(total_hits)
    connection.stub!(:query).and_return(response)
  end

  def config
    @config ||= Sunspot::Configuration.build

  end

  def connection
    @connection ||= mock('connection')
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end
end
