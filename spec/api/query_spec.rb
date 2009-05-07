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
end
