require File.join(File.dirname(__FILE__), 'test_helper')

#TODO USE FILTER QUERIES!!!
class TestSearch < Test::Unit::TestCase
  include RR::Adapters::TestUnit

  before do
    stub(Solr::Connection).new { connection }
  end

  test 'should search by keywords' do
    connection.query('(keyword search) AND (type:Post)').times(2)
    Post.search :keywords => 'keyword search'
    Post.search do
      keywords 'keyword search'
    end
  end

  test 'should scope by exact match with a string' do
    connection.query('(title_s:My\ Pet\ Post) AND (type:Post)').times(2)
    Post.search :conditions => { :title => 'My Pet Post' }
    Post.search do
      with.title 'My Pet Post'
    end
  end

  test 'should ignore nonexistant fields in hash scope' do
    connection.query('(type:Post)')
    Post.search :conditions => { :bogus => 'Field' }
  end

  test 'should raise an ArgumentError for nonexistant fields in block scope' do
    lambda do 
      Post.search do
        with.bogus 'Field'
      end
    end.should raise_error(ArgumentError)
  end

  test 'should scope by exact match with time' do
    connection.query('(published_at_d:1983\-07\-08T09\:00\:00Z) AND (type:Post)').times(2)
    time = Time.parse('1983-07-08 05:00:00 -0400')
    Post.search :conditions => { :published_at => time }
    Post.search do
      with.published_at time
    end
  end

  test 'should scope by less than match with float' do
    connection.query('(average_rating_f:[* TO 3\.0]) AND (type:Post)').times(2)

    Post.search :conditions => { :average_rating => 3.0 } do
      conditions.interpret :average_rating, :less_than
    end

    Post.search do
      with.average_rating.less_than 3.0
    end
  end

  test 'should scope by greater than match with float' do
    connection.query('(average_rating_f:[3\.0 TO *]) AND (type:Post)').times(2)
    Post.search :conditions => { :average_rating => 3.0 } do 
      conditions.interpret :average_rating, :greater_than
    end
    Post.search do
      with.average_rating.greater_than 3.0
    end
  end

  test 'should scope by between match with float' do
    connection.query('(average_rating_f:[2\.0 TO 4\.0]) AND (type:Post)').times(2)
    Post.search :conditions => { :average_rating => [2.0, 4.0] } do
      conditions.interpret :average_rating, :between
    end
    Post.search do
      with.average_rating.between 2.0..4.0
    end
  end

  test 'should scope by any match with integer' do
    connection.query('(category_ids_i:(2 OR 7 OR 12)) AND (type:Post)').times(2) #TODO confirm that this is the right syntax for Solr
    Post.search :conditions => { :category_ids => [2, 7, 12] }
    Post.search do
      with.category_ids.any_of [2, 7, 12]
    end
  end

  test 'should scope by all match with integer' do
    connection.query('(category_ids_i:(2 AND 7 AND 12)) AND (type:Post)').times(2) #TODO confirm that this is the right syntax for Solr
    Post.search :conditions => { :category_ids => [2, 7, 12] } do
      conditions.interpret :category_ids, :all_of
    end
    Post.search do
      with.category_ids.all_of [2, 7, 12]
    end
  end

  test 'should allow setting of default conditions' do
    connection.query('(average_rating_f:2\.0) AND (type:Post)')
    Post.search do
      conditions.default :average_rating, 2.0
    end
  end

  test 'should not use default condition value if condition provided' do
    connection.query('(average_rating_f:3\.0) AND (type:Post)')
    Post.search :conditions => { :average_rating => 3.0 } do
      conditions.default :average_rating, 2.0
    end
  end

  test 'should raise ArgumentError if bogus field scoped' do
    lambda do
      Post.search do
        with.bogus.equal_to :field
      end
    end.should raise_error(ArgumentError)
  end

  test 'should raise NoMethodError if bogus operator referenced' do
    lambda do
      Post.search do
        with.category_ids.resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  test 'should raise NoMethodError if more than one argument passed to scope method' do # or should it?
    lambda do
      Post.search do
        with.category_ids 4, 5
      end
    end.should raise_error(NoMethodError)
  end

  private

  def connection
    @connection ||= mock!
  end
end
