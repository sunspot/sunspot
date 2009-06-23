require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Session' do
  context 'using singleton session' do
    before :each do
      Sunspot.reset!
      connection.should_receive(:add).twice
      connection.should_receive(:commit).twice
      connection.should_receive(:query)
    end

    it 'should open connection with defaults if nothing specified' do
      Solr::Connection.stub!(:new).with('http://localhost:8983/solr').and_return(connection)
      Sunspot.index(Post.new)
      Sunspot.index!(Post.new)
      Sunspot.commit
      Sunspot.search(Post)
    end

    it 'should open a connection with custom host' do
      Solr::Connection.stub!(:new).with('http://127.0.0.1:8981/solr').and_return(connection)
      Sunspot.config.solr.url = 'http://127.0.0.1:8981/solr'
      Sunspot.index(Post.new)
      Sunspot.index!(Post.new)
      Sunspot.commit
      Sunspot.search(Post)
    end
  end

  context 'using custom session' do
    before :each do
      connection.should_receive(:add).twice
      connection.should_receive(:commit).twice
      connection.should_receive(:query)
    end

    it 'should open a connection with custom host' do
      Solr::Connection.stub!(:new).with('http://127.0.0.1:8982/solr').and_return(connection)
      session = Sunspot::Session.new do |config|
        config.solr.url = 'http://127.0.0.1:8982/solr'
      end
      session.index(Post.new)
      session.index!(Post.new)
      session.commit
      session.search(Post)
    end
  end

  context 'dirty sessions' do
    before :each do
      connection.stub!(:add)
      connection.stub!(:commit)
      Solr::Connection.stub!(:new).and_return(connection)
      @session = Sunspot::Session.new
    end

    it 'should start out not dirty' do
      @session.dirty?.should be_false
    end

    it 'should be dirty after adding an item' do
      @session.index(Post.new)
      @session.dirty?.should be_true
    end

    it 'should be dirty after deleting an item' do
      @session.remove(Post.new)
      @session.dirty?.should be_true
    end

    it 'should be dirty after a remove_all for a class' do
      @session.remove_all(Post)
      @session.dirty?.should be_true
    end

    it 'should be dirty after a global remove_all' do
      @session.remove_all
      @session.dirty?.should be_true
    end

    it 'should not be dirty after a commit' do
      @session.index(Post.new)
      @session.commit
      @session.dirty?.should be_false
    end

    it 'should not commit when commit_if_dirty called on clean session' do
      connection.should_not_receive(:commit)
      @session.commit_if_dirty
    end

    it 'should commit when commit_if_dirty called on dirty session' do
      connection.should_receive(:commit)
      @session.index(Post.new)
      @session.commit_if_dirty
    end
  end

  def connection
    @connection ||= mock('Connection').as_null_object
  end
end
