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

  if ENV['USE_WILL_PAGINATE']

    it 'should return search total as attribute of results if pagination is provided' do
      stub_results(Post.new, 4)
      session.search(Post, :page => 1).results.total_entries.should == 4
    end

  else

    it 'should return vanilla array if pagination is provided but WillPaginate is not available' do
      stub_results(Post.new)
      session.search(Post, :page => 1).results.should_not respond_to(:total_entries)
    end

  end

  it 'should return hits without loading instances' do
    post_1, post_2 = Array.new(2) { Post.new }
    stub_results(post_1, post_2)
    %w(load load_all).each { |message| MockAdapter::DataAccessor.should_not_receive(message) }
    session.search(Post, :page => 1).hits.map do |hit|
      [hit.class_name, hit.primary_key]
    end.should == [['Post', post_1.id.to_s], ['Post', post_2.id.to_s]]
  end

  it 'should attach score to hits' do
    stub_full_results('instance' => Post.new, 'score' => 1.23)
    session.search(Post).hits.first.score.should == 1.23
  end

  it 'should return stored field values in hits' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    session.search(Post).hits.first.stored[:title].should == 'Title'
  end

  it 'should return stored field values for searches against multiple types' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    session.search(Post, Namespaced::Comment).hits.first.stored[:title].should == 'Title'
  end

  it 'should typecast stored field values in hits' do
    time = Time.utc(2008, 7, 8, 2, 45)
    stub_full_results('instance' => Post.new, 'last_indexed_at_ds' => time.xmlschema)
    session.search(Post).hits.first.stored[:last_indexed_at].should == time
  end

  it 'should allow access to the data accessor' do
    stub_results(posts = Post.new)
    search = session.search Post do
      data_accessor_for(Post).custom_title = 'custom title'
    end
    search.results.first.title.should == 'custom title'
  end

  it 'should return total' do
    stub_results(Post.new, Post.new, 4)
    session.search(Post, :page => 1).total.should == 4
  end

  it 'should return field name for facet' do
    stub_facet(:title_ss, {})
    result = session.search Post do
      facet :title
    end
    result.facet(:title).field_name.should == :title
  end

  it 'should return string facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_values(result, :title).should == ['Author 1', 'Author 2']
  end

  it 'should return counts for facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
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
    stub_facet(
      :published_at_d,
      '2009-04-07T20:25:23Z' => 3,
      '2009-04-07T20:26:19Z' => 1
    )
    result = session.search Post do
      facet :published_at
    end
    facet_values(result, :published_at).should ==
      [Time.gm(2009, 04, 07, 20, 25, 23),
       Time.gm(2009, 04, 07, 20, 26, 19)]
  end

  it 'should return date facet' do
    stub_facet(
      :expire_date_d,
      '2009-07-13T00:00:00Z' => 3,
      '2009-04-01T00:00:00Z' => 1
    )
    result = session.search(Post) do
      facet :expire_date
    end
    facet_values(result, :expire_date).should ==
      [Date.new(2009, 07, 13),
       Date.new(2009, 04, 01)]
  end

  it 'should return boolean facet' do
    stub_facet(:featured_b, 'true' => 3, 'false' => 1)
    result = session.search(Post) { facet(:featured) }
    facet_values(result, :featured).should == [true, false]
  end

  it 'should return date range facet' do
    stub_date_facet(:published_at_d, 60*60*24, '2009-07-08T04:00:00Z' => 2, '2009-07-07T04:00:00Z' => 1)
    start_time = Time.utc(2009, 7, 7, 4)
    end_time = start_time + 2*24*60*60
    result = session.search(Post) { facet(:published_at, :time_range => start_time..end_time) }
    facet = result.facet(:published_at)
    facet.rows.first.value.should == (start_time..(start_time+24*60*60))
    facet.rows.last.value.should == ((start_time+24*60*60)..end_time)
  end

  it 'should return dynamic string facet' do
    stub_facet(:"custom_string:test_s", 'two' => 2, 'one' => 1)
    result = session.search(Post) { dynamic(:custom_string) { facet(:test) }}
    result.dynamic_facet(:custom_string, :test).rows.map { |row| row.value }.should == ['two', 'one']
  end

  it 'should return instantiated facet values' do
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    result = session.search(Post) { facet(:blog_id) }
    result.facet(:blog_id).rows.map { |row| row.instance }.should == blogs
  end

  it 'should only query the persistent store once for an instantiated facet' do
    query_count = Blog.query_count
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    result = session.search(Post) { facet(:blog_id) }
    result.facet(:blog_id).rows.each { |row| row.instance }
    (Blog.query_count - query_count).should == 1
  end

  private

  def stub_full_results(*results)
    count =
      if results.last.is_a?(Integer) then results.pop
      else results.length
      end
    docs = results.map do |result|
      instance = result.delete('instance')
      result.merge('id' => "#{instance.class.name} #{instance.id}")
    end
    response = {
      'response' => {
        'docs' => docs,
        'numFound' => count
      }
    }
    connection.stub!(:select).and_return(response)
  end

  def stub_results(*results)
    stub_full_results(
      *results.map do |result|
        if result.is_a?(Integer)
          result
        else
          { 'instance' => result }
        end
      end
    )
  end

  def stub_facet(name, values)
    connection.stub!(:select).and_return(
      'facet_counts' => {
        'facet_fields' => {
          name.to_s => values.to_a.sort_by { |value, count| -count }.flatten
        }
      }
    )
  end

  def stub_date_facet(name, gap, values)
    connection.stub!(:select).and_return(
      'facet_counts' => {
        'facet_dates' => {
          name.to_s => { 'gap' => "+#{gap}SECONDS" }.merge(values)
        }
      }
    )
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
