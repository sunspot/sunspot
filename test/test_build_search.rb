require File.join(File.dirname(__FILE__), 'test_helper')

class TestBuildSearch < Test::Unit::TestCase
  include RR::Adapters::TestUnit

  before do
    stub(Solr::Connection).new { connection }
  end

  test 'should search by keywords' do
    mock(connection).query('(keyword search) AND (type:Post)', :filter_queries => []).times(2)
    Sunspot.search Post, :keywords => 'keyword search'
    Sunspot.search Post do
      keywords 'keyword search'
    end
  end

  test 'should scope by exact match with a string' do
    mock(connection).query('(type:Post)', :filter_queries => ['title_s:My\ Pet\ Post']).times(2)
    Sunspot.search Post, :conditions => { :title => 'My Pet Post' }
    Sunspot.search Post do
      with.title 'My Pet Post'
    end
  end

  test 'should ignore nonexistant fields in hash scope' do
    mock(connection).query('(type:Post)', :filter_queries => [])
    Sunspot.search Post, :conditions => { :bogus => 'Field' }
  end

  test 'should raise an ArgumentError for nonexistant fields in block scope' do
    lambda do 
      Sunspot.search Post do
        with.bogus 'Field'
      end
    end.should raise_error(ArgumentError)
  end

  test 'should scope by exact match with time' do
    mock(connection).query('(type:Post)', :filter_queries => ['published_at_d:1983\-07\-08T09\:00\:00Z']).times(2)
    time = Time.parse('1983-07-08 05:00:00 -0400')
    Sunspot.search Post, :conditions => { :published_at => time }
    Sunspot.search Post do
      with.published_at time
    end
  end

  test 'should scope by less than match with float' do
    mock(connection).query('(type:Post)', :filter_queries => ['average_rating_f:[* TO 3\.0]']).times(2)

    Sunspot.search Post, :conditions => { :average_rating => 3.0 } do
      conditions.interpret :average_rating, :less_than
    end

    Sunspot.search Post do
      with.average_rating.less_than 3.0
    end
  end

  test 'should scope by greater than match with float' do
    mock(connection).query('(type:Post)', :filter_queries => ['average_rating_f:[3\.0 TO *]']).times(2)
    Sunspot.search Post, :conditions => { :average_rating => 3.0 } do 
      conditions.interpret :average_rating, :greater_than
    end
    Sunspot.search Post do
      with.average_rating.greater_than 3.0
    end
  end

  test 'should scope by between match with float' do
    mock(connection).query('(type:Post)', :filter_queries => ['average_rating_f:[2\.0 TO 4\.0]']).times(2)
    Sunspot.search Post, :conditions => { :average_rating => [2.0, 4.0] } do
      conditions.interpret :average_rating, :between
    end
    Sunspot.search Post do
      with.average_rating.between 2.0..4.0
    end
  end

  test 'should scope by any match with integer' do
    mock(connection).query('(type:Post)', :filter_queries => ['category_ids_im:(2 OR 7 OR 12)']).times(2)
    Sunspot.search Post, :conditions => { :category_ids => [2, 7, 12] }
    Sunspot.search Post do
      with.category_ids.any_of [2, 7, 12]
    end
  end

  test 'should scope by all match with integer' do
    mock(connection).query('(type:Post)', :filter_queries => ['category_ids_im:(2 AND 7 AND 12)']).times(2)
    Sunspot.search Post, :conditions => { :category_ids => [2, 7, 12] } do
      conditions.interpret :category_ids, :all_of
    end
    Sunspot.search Post do
      with.category_ids.all_of [2, 7, 12]
    end
  end

  test 'should allow setting of default conditions' do
    mock(connection).query('(type:Post)', :filter_queries => ['average_rating_f:2\.0'])
    Sunspot.search Post do
      conditions.default :average_rating, 2.0
    end
  end

  test 'should not use default condition value if condition provided' do
    mock(connection).query('(type:Post)', :filter_queries => ['average_rating_f:3\.0'])
    Sunspot.search Post, :conditions => { :average_rating => 3.0 } do
      conditions.default :average_rating, 2.0
    end
  end

  test 'should paginate using default per_page' do
    mock(connection).query('(type:Post)', :filter_queries => [], :rows => 30, :start => 30).times(2)
    Sunspot.search Post, :page => 2
    Sunspot.search Post do
      paginate :page => 2
    end
  end

  test 'should paginate using provided per_page' do
    mock(connection).query('(type:Post)', :filter_queries => [], :rows => 15, :start => 45).times(2)
    Sunspot.search Post, :page => 4, :per_page => 15
    Sunspot.search Post do
      paginate :page => 4, :per_page => 15
    end
  end

  test 'should order' do
    mock(connection).query('(type:Post)', :filter_queries => [], :sort => 'average_rating_f desc').times(2)
    Sunspot.search Post, :order => 'average_rating desc'
    Sunspot.search Post do
      order_by :average_rating, :desc
    end
  end

  test 'should raise ArgumentError if bogus field scoped' do
    lambda do
      Sunspot.search Post do
        with.bogus.equal_to :field
      end
    end.should raise_error(ArgumentError)
  end

  test 'should raise NoMethodError if bogus operator referenced' do
    lambda do
      Sunspot.search Post do
        with.category_ids.resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  test 'should raise ArgumentError if no :page argument given to paginate' do
    lambda do
      Sunspot.search Post do
        paginate
      end
    end.should raise_error(ArgumentError)
  end

  test 'should raise ArgumentError if bogus argument given to paginate' do
    lambda do
      Sunspot.search Post do
        paginate :page => 4, :ugly => :puppy
      end
    end.should raise_error(ArgumentError)
  end

  test 'should raise NoMethodError if more than one argument passed to scope method' do # or should it?
    lambda do
      Sunspot.search Post do
        with.category_ids 4, 5
      end
    end.should raise_error(NoMethodError)
  end

  private

  def connection
    @connection ||= Object.new
  end
end
