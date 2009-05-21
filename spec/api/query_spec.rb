require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Query do
  before :each do
    @config ||= Sunspot::Configuration.build
    @connection ||= mock('connection')
    @session ||= Sunspot::Session.new(@config, @connection)
    @search = @session.new_search(Post)
  end

  after :each do
    @search.execute!
  end

  it 'should perform keyword search' do
    @search.query.keywords = 'keyword search'
    @connection.should_receive(:query).with('(keyword search) AND (type:Post)', hash_including)
  end

  it 'should add equality restriction' do
    @search.query.add_restriction(:title, :equal_to, 'My Pet Post')
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['title_s:My\ Pet\ Post']))
  end

  it 'should add less than restriction' do
    @search.query.add_restriction(:average_rating, :less_than, 3.0)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[* TO 3\.0]']))
  end

  it 'should add greater than restriction' do
    @search.query.add_restriction(:average_rating, :greater_than, 3.0)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[3\.0 TO *]']))
  end

  it 'should add between restriction' do
    @search.query.add_restriction(:average_rating, :between, 2.0..4.0)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[2\.0 TO 4\.0]']))
  end

  it 'should add any restriction' do
    @search.query.add_restriction(:category_ids, :any_of, [2, 7, 12])
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 OR 7 OR 12)']))
  end

  it 'should add all restriction' do
    @search.query.add_restriction(:category_ids, :all_of, [2, 7, 12])
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 AND 7 AND 12)']))
  end

  it 'should negate restriction' do
    @search.query.add_negated_restriction(:title, :equal_to, 'Bad Post')
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-title_s:Bad\ Post']))
  end

  it 'should exclude instance' do
    post = Post.new
    @search.query.exclude_instance(post)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ["-id:Post\\ #{post.id}"]))
  end

  it 'should paginate using default per-page' do
    @search.query.paginate(2)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:rows => 30, :start => 30))
  end
  
  it 'should paginate using provided per-page' do
    @search.query.paginate(4, 15)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:rows => 15, :start => 45))
  end

  it 'should order ascending by default' do
    @search.query.order_by(:average_rating)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:sort => [{ :average_rating_f => :ascending }]))
  end

  it 'should order descending if specified' do
    @search.query.order_by(:average_rating, :desc)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:sort => [{ :average_rating_f => :descending }]))
  end

  it 'should request a field facet' do
    @search.query.add_field_facet(:category_ids)
    @connection.should_receive(:query).with('(type:Post)', hash_including(:facets => { :fields => %w(category_ids_im) }))
  end

  it 'should restrict by dynamic string field with equality restriction' do
    @search.query.dynamic_query(:custom_string).add_restriction(:test, :equal_to, 'string')
    @connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['custom_string\:test_s:string']))
  end

  it 'should restrict by dynamic integer field with less than restriction' do
    @search.query.dynamic_query(:custom_integer).add_restriction(:test, :less_than, 1)
    @connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_integer\:test_i:[* TO 1]']))
  end

  it 'should restrict by dynamic float field with between restriction' do
    @search.query.dynamic_query(:custom_float).add_restriction(:test, :between, 2.2..3.3)
    @connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_float\:test_fm:[2\.2 TO 3\.3]']))
  end

  it 'should restrict by dynamic time field with any of restriction' do
    @search.query.dynamic_query(:custom_time).add_restriction(:test, :any_of,
                                                              [Time.parse('2009-02-10 14:00:00 UTC'),
                                                               Time.parse('2009-02-13 18:00:00 UTC')])
    @connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)']))
  end

  it 'should restrict by dynamic boolean field with equality restriction' do
    @search.query.dynamic_query(:custom_boolean).add_restriction(:test, :equal_to, false)
    @connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_boolean\:test_b:false']))
  end

  it 'should negate a dynamic field restriction' do
    @search.query.dynamic_query(:custom_string).add_negated_restriction(:test, :equal_to, 'foo')
    @connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['-custom_string\:test_s:foo']))
  end

  it 'should order by a dynamic field' do
    @search.query.dynamic_query(:custom_integer).order_by(:test, :desc)
    @connection.should_receive(:query).with(anything, hash_including(:sort => [{ :"custom_integer:test_i" => :descending }]))
  end

  it 'should order by a dynamic field and static field, with given precedence' do
    @search.query.dynamic_query(:custom_integer).order_by(:test, :desc)
    @search.query.order_by(:sort_title, :asc)
    @connection.should_receive(:query).with(anything, hash_including(:sort => [{ :"custom_integer:test_i" => :descending },
                                                                               { :sort_title_s => :ascending}]))
  end
end
