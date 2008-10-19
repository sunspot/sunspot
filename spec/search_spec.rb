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
  
  private

  def connection
    @connection ||= stub('Connection')
  end
end
