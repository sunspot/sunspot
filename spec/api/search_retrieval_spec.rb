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

  it 'should return raw results without loading instances' do
    post_1, post_2 = Array.new(2) { Post.new }
    stub_results(post_1, post_2)
    MockAdapter::DataAccessor.should_not_receive(:new)
    session.search(Post, :page => 1).raw_results.map do |raw_result|
      [raw_result.class_name, raw_result.primary_key]
    end.should == [['Post', post_1.id.to_s], ['Post', post_2.id.to_s]]
  end
  
  it 'should load results with integer-ids to avoid conflicts with sluggable finders' do
    stub_results(post = Post.new)
    mock_adapter = mock()
    mock_adapter.should_receive(:load_all).with([post.id]).and_return([post])
    MockAdapter::DataAccessor.should_receive(:new).at_least(1).and_return( mock_adapter )
    session.search(Post).results.should == [post]
  end

  it 'should return total' do
    stub_results(Post.new, Post.new, 4)
    session.search(Post, :page => 1).total.should == 4
  end

  it 'should return field name for facet' do
    stub_facet(:title_s, {})
    result = session.search Post do
      facet :title
    end
    result.facet(:title).field_name.should == :title
  end

  it 'should return string facet' do
    stub_facet(:title_s, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_values(result, :title).should == ['Author 1', 'Author 2']
  end

  it 'should return counts for facet' do
    stub_facet(:title_s, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_counts(result, :title).should == [2, 1]
  end

  it 'should return integer facet' do
    stub_facet(:blog_id_i, '3' => 2, '1' => 1)
    result = session.search Post do
      facet :blog_id
    end
    facet_values(result, :blog_id).should == [3, 1]
  end

  it 'should return float facet' do
    stub_facet(:average_rating_f, '9.3' => 2, '1.1' => 1)
    result = session.search Post do
      facet :average_rating
    end
    facet_values(result, :average_rating).should == [9.3, 1.1]
  end

  it 'should return time facet' do
    stub_facet(:published_at_d, '2009-04-07T20:25:23Z' => 3, '2009-04-07T20:26:19Z' => 1)
    result = session.search Post do
      facet :published_at
    end
    facet_values(result, :published_at).should == [Time.gm(2009, 04, 07, 20, 25, 23),
                                                   Time.gm(2009, 04, 07, 20, 26, 19)]
  end

  it 'should return boolean facet' do
    stub_facet(:featured_b, 'true' => 3, 'false' => 1)
    result = session.search(Post) { facet(:featured) }
    facet_values(result, :featured).should == [true, false]
  end

  it 'should return dynamic string facet' do
    stub_facet(:"custom_string:test_s", 'two' => 2, 'one' => 1)
    result = session.search(Post) { dynamic(:custom_string) { facet(:test) }}
    result.dynamic_facet(:custom_string, :test).rows.map { |row| row.value }.should == ['two', 'one']
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

  def stub_facet(name, values)
    response = mock('response')
    facets = values.map do |data, count|
      value = Solr::Response::Standard::FacetValue.new
      value.name = data
      value.value = count
      value
    end.sort_by { |value| -value.value }
    response.stub!(:field_facets).with(name.to_s).and_return(facets)
    connection.stub!(:query).and_return(response)
  end

  def facet_values(result, field_name)
    result.facet(field_name).rows.map { |row| row.value }
  end

  def facet_counts(result, field_name)
    result.facet(field_name).rows.map { |row| row.count }
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
