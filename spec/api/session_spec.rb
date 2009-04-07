require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Session' do
  context 'using singleton session' do
    before :each do
      Sunspot.reset!
      connection.should_receive(:add)
      connection.should_receive(:query)
    end

    it 'should open connection with defaults if nothing specified' do
      Solr::Connection.stub!(:new).with('http://localhost:8983/solr', :autocommit => :on).and_return(connection)
      Sunspot.index(Post.new)
      Sunspot.search(Post)
    end

    it 'should open a connection with custom host' do
      Solr::Connection.stub!(:new).with('http://127.0.0.1:8981/solr', :autocommit => :on).and_return(connection)
      Sunspot.config.solr.url = 'http://127.0.0.1:8981/solr'
      Sunspot.index(Post.new)
      Sunspot.search(Post)
    end
  end

  context 'using custom session' do
    before :each do
      connection.should_receive(:add)
      connection.should_receive(:query)
    end

    it 'should open a connection with custom host' do
      Solr::Connection.stub!(:new).with('http://127.0.0.1:8982/solr', :autocommit => :on).and_return(connection)
      session = Sunspot::Session.new do |config|
        config.solr.url = 'http://127.0.0.1:8982/solr'
      end
      session.index(Post.new)
      session.search(Post)
    end
  end

  def connection
    @connection ||= mock('Connection').as_null_object
  end
end
