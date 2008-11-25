require File.join(File.dirname(__FILE__), 'test_helper')
require 'mocha'

class TestSession < Test::Unit::TestCase
  context 'using singleton session' do
    before do
      Sunspot.reset!
      connection.expects(:add)
      connection.expects(:query)
    end

    after do
    end

    test 'should create connection with defaults if nothing specified' do
      Solr::Connection.stubs(:new).with('http://localhost:8983/solr', :autocommit => :on).returns(connection)
      Sunspot.index(Post.new)
      Sunspot.search(Post)
    end

    test 'should create a connection with custom host' do
      Solr::Connection.stubs(:new).with('http://127.0.0.1:8981/solr', :autocommit => :on).returns(connection)
      Sunspot.config.solr.url = 'http://127.0.0.1:8981/solr'
      Sunspot.index(Post.new)
      Sunspot.search(Post)
    end
  end

  private

  def connection
    @connection ||= stub_everything('Connection')
  end
end
