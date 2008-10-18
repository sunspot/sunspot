require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Search do
  before :each do
    Solr::Connection.stub!(:new).and_return connection
  end

  it 'should allow searching by keywords' do
    connection.should_receive(:query).with('(keyword search) AND (type:Post)').twice
    Post.search :keywords => 'keyword search'
    Post.search { keywords 'keyword search' }
  end
  
  private

  def connection
    @connection ||= stub('Connection')
  end
end
