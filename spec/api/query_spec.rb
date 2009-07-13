require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Query do
  before :each do
    @config ||= Sunspot::Configuration.build
    @connection ||= Mock::Connection.new
    @session ||= Sunspot::Session.new(@config, @connection)
    @search = @session.new_search(Post)
  end

  it 'should perform keyword search' do
    @search.query.keywords = 'keyword search'
    @search.execute!
    @connection.should have_last_search_with(:q => 'keyword search')
  end

  it 'should add equality restriction' do
    @search.query.add_restriction(:title, :equal_to, 'My Pet Post')
    @search.execute!
    @connection.should have_last_search_with(:fq => ['title_ss:My\ Pet\ Post'])
  end

  it 'should add less than restriction' do
    @search.query.add_restriction(:average_rating, :less_than, 3.0)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['average_rating_f:[* TO 3\.0]'])
  end

  it 'should add greater than restriction' do
    @search.query.add_restriction(:average_rating, :greater_than, 3.0)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['average_rating_f:[3\.0 TO *]'])
  end

  it 'should add between restriction' do
    @search.query.add_restriction(:average_rating, :between, 2.0..4.0)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['average_rating_f:[2\.0 TO 4\.0]'])
  end

  it 'should add any restriction' do
    @search.query.add_restriction(:category_ids, :any_of, [2, 7, 12])
    @search.execute!
    @connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should add all restriction' do
    @search.query.add_restriction(:category_ids, :all_of, [2, 7, 12])
    @search.execute!
    @connection.should have_last_search_with(:fq => ['category_ids_im:(2 AND 7 AND 12)'])
  end

  it 'should negate restriction' do
    @search.query.add_negated_restriction(:title, :equal_to, 'Bad Post')
    @search.execute!
    @connection.should have_last_search_with(:fq => ['-title_ss:Bad\ Post'])
  end

  it 'should exclude instance' do
    post = Post.new
    @search.query.exclude_instance(post)
    @search.execute!
    @connection.should have_last_search_with(:fq => ["-id:Post\\ #{post.id}"])
  end

  it 'should paginate using default per-page' do
    @search.query.paginate(2)
    @search.execute!
    @connection.should have_last_search_with(:rows => 30)
  end
  
  it 'should paginate using provided per-page' do
    @search.query.paginate(4, 15)
    @search.execute!
    @connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'should order ascending by default' do
    @search.query.order_by(:average_rating)
    @search.execute!
    @connection.should have_last_search_with(:sort => 'average_rating_f asc')
  end

  it 'should order descending if specified' do
    @search.query.order_by(:average_rating, :desc)
    @search.execute!
    @connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'should request a field facet' do
    @search.query.add_field_facet(:category_ids)
    @search.execute!
    @connection.should have_last_search_with(:"facet.field" => %w(category_ids_im))
  end

  it 'should restrict by dynamic string field with equality restriction' do
    @search.query.dynamic_query(:custom_string).add_restriction(:test, :equal_to, 'string')
    @search.execute!
    @connection.should have_last_search_with(:fq => ['custom_string\:test_s:string'])
  end

  it 'should restrict by dynamic integer field with less than restriction' do
    @search.query.dynamic_query(:custom_integer).add_restriction(:test, :less_than, 1)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['custom_integer\:test_i:[* TO 1]'])
  end

  it 'should restrict by dynamic float field with between restriction' do
    @search.query.dynamic_query(:custom_float).add_restriction(:test, :between, 2.2..3.3)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['custom_float\:test_fm:[2\.2 TO 3\.3]'])
  end

  it 'should restrict by dynamic time field with any of restriction' do
    @search.query.dynamic_query(:custom_time).add_restriction(
      :test,
      :any_of,
      [Time.parse('2009-02-10 14:00:00 UTC'),
       Time.parse('2009-02-13 18:00:00 UTC')]
    )
    @search.execute!
    @connection.should have_last_search_with(
      :fq => ['custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)']
    )
  end

  it 'should restrict by dynamic boolean field with equality restriction' do
    @search.query.dynamic_query(:custom_boolean).add_restriction(:test, :equal_to, false)
    @search.execute!
    @connection.should have_last_search_with(:fq => ['custom_boolean\:test_b:false'])
  end

  it 'should negate a dynamic field restriction' do
    @search.query.dynamic_query(:custom_string).add_negated_restriction(:test, :equal_to, 'foo')
    @search.execute!
    @connection.should have_last_search_with(:fq => ['-custom_string\:test_s:foo'])
  end

  it 'should order by a dynamic field' do
    @search.query.dynamic_query(:custom_integer).order_by(:test, :desc)
    @search.execute!
    @connection.should have_last_search_with(:sort => 'custom_integer:test_i desc')
  end

  it 'should order by a dynamic field and static field, with given precedence' do
    @search.query.dynamic_query(:custom_integer).order_by(:test, :desc)
    @search.query.order_by(:sort_title, :asc)
    @search.execute!
    @connection.should have_last_search_with(
      :sort => 'custom_integer:test_i desc, sort_title_s asc'
    )
  end
end
