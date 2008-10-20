require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Search do
  before :each do
    Solr::Connection.stub!(:new).and_return connection
  end

  it 'should search by keywords' do
    connection.should_receive(:query).with('(keyword search) AND (type:Post)').twice
    Post.search :keywords => 'keyword search'
    Post.search do
      keywords 'keyword search'
    end
  end

  it 'should scope by exact match with a string' do
    connection.should_receive(:query).with('(title_s:My\ Pet\ Post) AND (type:Post)').twice
    Post.search :conditions => { :title => 'My Pet Post' }
    Post.search do
      with.title 'My Pet Post'
    end
  end

  it 'should ignore nonexistant fields in hash scope' do
    connection.should_receive(:query).with('(type:Post)')
    Post.search :conditions => { :bogus => 'Field' }
  end

  it 'should raise an ArgumentError for nonexistant fields in block scope' do
    lambda do 
      Post.search do
        with.bogus 'Field'
      end
    end.should raise_error(ArgumentError)
  end

  it 'should scope by exact match with time' do
    connection.should_receive(:query).with('(published_at_d:1983\-07\-08T09\:00\:00Z) AND (type:Post)').twice
    time = Time.parse('1983-07-08 05:00:00 -0400')
    Post.search :conditions => { :published_at => time }
    Post.search do
      with.published_at time
    end
  end

  it 'should scope by less than match with float using block syntax' do
    connection.should_receive(:query).with('(average_rating_f:[* TO 3\.0]) AND (type:Post)')
    Post.search do
      with.average_rating.less_than 3.0
    end
  end

  it 'should scope by greater than match with float using block syntax' do
    connection.should_receive(:query).with('(average_rating_f:[3\.0 TO *]) AND (type:Post)')
    Post.search do
      with.average_rating.greater_than 3.0
    end
  end

  it 'should scope by between match with float using block syntax' do
    connection.should_receive(:query).with('(average_rating_f:[2\.0 TO 4\.0]) AND (type:Post)')
    Post.search do
      with.average_rating.between 2.0..4.0
    end
  end

  it 'should scope by any match with integer' do
    connection.should_receive(:query).with('(category_ids_i:(2 OR 7 OR 12)) AND (type:Post)').twice #TODO confirm that this is the right syntax for Solr
    Post.search :conditions => { :category_ids => [2, 7, 12] }
    Post.search do
      with.category_ids.any_of [2, 7, 12]
    end
  end

  it 'should scope by all match with integer using block syntax' do
    connection.should_receive(:query).with('(category_ids_i:(2 AND 7 AND 12)) AND (type:Post)') #TODO confirm that this is the right syntax for Solr
    Post.search do
      with.category_ids.all_of [2, 7, 12]
    end
  end

  it 'should raise ArgumentError if bogus field scoped' do
    lambda do
      Post.search do
        with.bogus.equal_to :field
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise NoMethodError if bogus condition name referenced' do
    lambda do
      Post.search do
        with.category_ids.resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  it 'should raise NoMethodError if more than one argument passed to scope method' do # or should it?
    lambda do
      Post.search do
        with.category_ids 4, 5
      end
    end.should raise_error(NoMethodError)
  end

  private

  def connection
    @connection ||= stub('Connection')
  end
end
