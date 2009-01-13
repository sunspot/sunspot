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

  it 'should give access to order through hash and object' do
    stub_results
    search = session.search(Post, :order => 'sort_title asc')
    search.attributes[:order].should == 'sort_title asc'
    search.order.should == 'sort_title asc'
  end

  it 'should give nil order if no order set' do
    stub_results
    search = session.search(Post)
    search.attributes.should have_key(:order)
    search.attributes[:order].should be_nil
    search.order.should be_nil
  end

  it 'should give access to page and per-page through hash and object' do
    stub_results
    search = session.search(Post, :page => 2, :per_page => 15)
    search.attributes[:page].should == 2
    search.attributes[:per_page].should == 15
    search.page.should == 2
    search.per_page.should == 15
  end

  it 'should give access to keywords' do
    stub_results
    search = session.search(Post, :keywords => 'some keywords')
    search.attributes[:keywords].should == 'some keywords'
    search.keywords.should == 'some keywords'
  end

  it 'should have nil keywords if no keywords given' do
    stub_results
    search = session.search(Post)
    search.attributes.should have_key(:keywords)
    search.attributes[:keywords].should be_nil
    search.keywords.should be_nil
  end

  it 'should give access to conditions' do
    stub_results
    search = session.search(Post, :conditions => { :blog_id => 1 })
    search.attributes[:conditions][:blog_id].should == 1
    search.conditions.blog_id.should == 1
  end

  it 'should have nil values for fields with unspecified conditions' do
    stub_results
    search = session.search(Post)
    %w(title blog_id category_ids average_rating published_at sort_title).each do |field_name|
      search.attributes[:conditions].should have_key(field_name.to_sym)
      search.attributes[:conditions][field_name.to_sym].should == nil
      search.conditions.should respond_to(field_name)
      search.conditions.send(field_name).should == nil
    end
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
