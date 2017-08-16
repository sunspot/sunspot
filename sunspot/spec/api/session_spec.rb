require File.expand_path('spec_helper', File.dirname(__FILE__))

shared_examples_for 'all sessions' do
  context '#index()' do
    before :each do
      @session.index(Post.new)
    end

    it 'should add document to connection' do
      expect(connection.adds.size).to eq(1)
    end
  end

  context '#index!()' do
    before :each do
      @session.index!(Post.new)
    end

    it 'should add document to connection' do
      expect(connection.adds.size).to eq(1)
    end

    it 'should commit' do
      expect(connection.commits.size).to eq(1)
    end
  end

  context '#commit()' do
    before :each do
      @session.commit
    end

    it 'should commit' do
      expect(connection.commits.size).to eq(1)
    end
  end

  context '#commit(bool)' do
    it 'should soft-commit if bool=true' do
      @session.commit(true)
      expect(connection.commits.size).to eq(1)
      expect(connection.soft_commits.size).to eq(1)
    end

    it 'should hard-commit if bool=false' do
      @session.commit(false)
      expect(connection.commits.size).to eq(1)
      expect(connection.soft_commits.size).to eq(0)
    end

    it 'should hard-commit if bool is not specified' do
      @session.commit
      expect(connection.commits.size).to eq(1)
      expect(connection.soft_commits.size).to eq(0)
    end
  end

  context '#optimize()' do
    before :each do
      @session.optimize
    end

    it 'should optimize' do
      expect(connection.optims.size).to eq(1)
    end
  end

  context '#search()' do
    before :each do
      @session.search(Post)
    end

    it 'should search' do
      expect(connection.searches.size).to eq(1)
    end
  end
end

describe 'Session' do
  before :each do
    @connection_factory = Mock::ConnectionFactory.new
    Sunspot::Session.connection_class = @connection_factory
  end

  after :each do
    Sunspot::Session.connection_class = nil
    Sunspot.reset!
  end

  context 'singleton session' do
    before :each do
      Sunspot.reset!
      @session = Sunspot
    end

    it_should_behave_like 'all sessions'

    it 'should open connection with defaults if nothing specified' do
      Sunspot.commit
      expect(connection.opts[:url]).to eq('http://127.0.0.1:8983/solr/default')
    end

    it 'should open a connection with custom host' do
      Sunspot.config.solr.url = 'http://127.0.0.1:8981/solr'
      Sunspot.commit
      expect(connection.opts[:url]).to eq('http://127.0.0.1:8981/solr')
    end

    it 'should open a connection with custom read timeout' do
      Sunspot.config.solr.read_timeout = 0.5
      Sunspot.commit
      expect(connection.opts[:read_timeout]).to eq(0.5)
    end

    it 'should open a connection with custom open timeout' do
      Sunspot.config.solr.open_timeout = 0.5
      Sunspot.commit
      expect(connection.opts[:open_timeout]).to eq(0.5)
    end

    it 'should open a connection through a provided proxy' do
      Sunspot.config.solr.proxy = 'http://proxy.com:1234'
      Sunspot.commit
      expect(connection.opts[:proxy]).to eq('http://proxy.com:1234')
    end
  end

  context 'custom session' do
    before :each do
      @session = Sunspot::Session.new
    end

    it_should_behave_like 'all sessions'

    it 'should open a connection with custom host' do
      session = Sunspot::Session.new do |config|
        config.solr.url = 'http://127.0.0.1:8982/solr'
      end
      session.commit
      expect(connection.opts[:url]).to eq('http://127.0.0.1:8982/solr')
    end
  end

  context 'dirty sessions' do
    before :each do
      @session = Sunspot::Session.new
    end

    it 'should start out not dirty' do
      expect(@session.dirty?).to be(false)
    end

    it 'should start out not delete_dirty' do
      expect(@session.delete_dirty?).to be(false)
    end

    it 'should be dirty after adding an item' do
      @session.index(Post.new)
      expect(@session.dirty?).to be(true)
    end

    it 'should be not be delete_dirty after adding an item' do
      @session.index(Post.new)
      expect(@session.delete_dirty?).to be(false)
    end

    it 'should be dirty after deleting an item' do
      @session.remove(Post.new)
      expect(@session.dirty?).to be(true)
    end

    it 'should be delete_dirty after deleting an item' do
      @session.remove(Post.new)
      expect(@session.delete_dirty?).to be(true)
    end

    it 'should be dirty after a remove_all for a class' do
      @session.remove_all(Post)
      expect(@session.dirty?).to be(true)
    end

    it 'should be delete_dirty after a remove_all for a class' do
      @session.remove_all(Post)
      expect(@session.delete_dirty?).to be(true)
    end

    it 'should be dirty after a global remove_all' do
      @session.remove_all
      expect(@session.dirty?).to be(true)
    end

    it 'should be delete_dirty after a global remove_all' do
      @session.remove_all
      expect(@session.delete_dirty?).to be(true)
    end

    it 'should not be dirty after a commit' do
      @session.index(Post.new)
      @session.commit
      expect(@session.dirty?).to be(false)
    end

    it 'should not be dirty after an optimize' do
      @session.index(Post.new)
      @session.optimize
      expect(@session.dirty?).to be(false)
    end

    it 'should not be delete_dirty after a commit' do
      @session.remove(Post.new)
      @session.commit
      expect(@session.delete_dirty?).to be(false)
    end

    it 'should not be delete_dirty after an optimize' do
      @session.remove(Post.new)
      @session.optimize
      expect(@session.delete_dirty?).to be(false)
    end

    it 'should not commit when commit_if_dirty called on clean session' do
      @session.commit_if_dirty
      expect(connection.commits.size).to eq(0)
    end

    it 'should not commit when commit_if_delete_dirty called on clean session' do
      @session.commit_if_delete_dirty
      expect(connection.commits.size).to eq(0)
    end

    it 'should hard commit when commit_if_dirty called on dirty session' do
      @session.index(Post.new)
      @session.commit_if_dirty
      expect(connection.commits.size).to eq(1)
    end

    it 'should soft commit when commit_if_dirty called on dirty session' do
      @session.index(Post.new)
      @session.commit_if_dirty(true)
      expect(connection.commits.size).to eq(1)
      expect(connection.soft_commits.size).to eq(1)
    end

    it 'should hard commit when commit_if_delete_dirty called on delete_dirty session' do
      @session.remove(Post.new)
      @session.commit_if_delete_dirty
      expect(connection.commits.size).to eq(1)
    end

    it 'should soft commit when commit_if_delete_dirty called on delete_dirty session' do
      @session.remove(Post.new)
      @session.commit_if_delete_dirty(true)
      expect(connection.commits.size).to eq(1)
      expect(connection.soft_commits.size).to eq(1)
    end
  end

  context 'session proxy' do
    it 'should send messages to manually assigned session proxy' do
      stub_session = double('session')
      Sunspot.session = stub_session
      post = Post.new
      expect(stub_session).to receive(:index).with(post)
      Sunspot.index(post)
      Sunspot.reset!
    end
  end

  def connection
    @connection_factory.instance
  end
end
