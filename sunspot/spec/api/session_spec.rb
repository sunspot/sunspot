require File.expand_path('spec_helper', File.dirname(__FILE__))

shared_examples_for 'all sessions' do
  context '#index()' do
    before :each do
      @session.index(Post.new)
    end

    it 'should add document to connection' do
      connection.should have(1).adds
    end
  end

  context '#index!()' do
    before :each do
      @session.index!(Post.new)
    end

    it 'should add document to connection' do
      connection.should have(1).adds
    end

    it 'should commit' do
      connection.should have(1).commits
    end
  end

  context '#commit()' do
    before :each do
      @session.commit
    end

    it 'should commit' do
      connection.should have(1).commits
    end
  end

  context '#optimize()' do
    before :each do
      @session.optimize
    end

    it 'should optimize' do
      connection.should have(1).optims
    end
  end

  context '#search()' do
    before :each do
      @session.search(Post)
    end

    it 'should search' do
      connection.should have(1).searches
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
      connection.opts[:url].should == 'http://127.0.0.1:8983/solr'
    end

    it 'should open a connection with custom host' do
      Sunspot.config.solr.url = 'http://127.0.0.1:8981/solr'
      Sunspot.commit
      connection.opts[:url].should == 'http://127.0.0.1:8981/solr'
    end

    it 'should open a connection with custom read timeout' do
      Sunspot.config.solr.read_timeout = 0.5
      Sunspot.commit
      connection.opts[:read_timeout].should == 0.5
    end

    it 'should open a connection with custom open timeout' do
      Sunspot.config.solr.open_timeout = 0.5
      Sunspot.commit
      connection.opts[:open_timeout].should == 0.5
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
      connection.opts[:url].should == 'http://127.0.0.1:8982/solr'
    end
  end

  context 'dirty sessions' do
    before :each do
      @session = Sunspot::Session.new
    end

    it 'should start out not dirty' do
      @session.dirty?.should be_false
    end
    
    it 'should start out not delete_dirty' do
      @session.delete_dirty?.should be_false
    end

    it 'should be dirty after adding an item' do
      @session.index(Post.new)
      @session.dirty?.should be_true
    end
    
    it 'should be not be delete_dirty after adding an item' do
      @session.index(Post.new)
      @session.delete_dirty?.should be_false
    end

    it 'should be dirty after deleting an item' do
      @session.remove(Post.new)
      @session.dirty?.should be_true
    end

    it 'should be delete_dirty after deleting an item' do
      @session.remove(Post.new)
      @session.delete_dirty?.should be_true
    end

    it 'should be dirty after a remove_all for a class' do
      @session.remove_all(Post)
      @session.dirty?.should be_true
    end

    it 'should be delete_dirty after a remove_all for a class' do
      @session.remove_all(Post)
      @session.delete_dirty?.should be_true
    end

    it 'should be dirty after a global remove_all' do
      @session.remove_all
      @session.dirty?.should be_true
    end
    
    it 'should be delete_dirty after a global remove_all' do
      @session.remove_all
      @session.delete_dirty?.should be_true
    end
    
    it 'should not be dirty after a commit' do
      @session.index(Post.new)
      @session.commit
      @session.dirty?.should be_false
    end

    it 'should not be dirty after an optimize' do
      @session.index(Post.new)
      @session.optimize
      @session.dirty?.should be_false
    end

    it 'should not be delete_dirty after a commit' do
      @session.remove(Post.new)
      @session.commit
      @session.delete_dirty?.should be_false
    end

    it 'should not be delete_dirty after an optimize' do
      @session.remove(Post.new)
      @session.optimize
      @session.delete_dirty?.should be_false
    end

    it 'should not commit when commit_if_dirty called on clean session' do
      @session.commit_if_dirty
      connection.should have(0).commits
    end

    it 'should not commit when commit_if_delete_dirty called on clean session' do
      @session.commit_if_delete_dirty
      connection.should have(0).commits
    end

    it 'should commit when commit_if_dirty called on dirty session' do
      @session.index(Post.new)
      @session.commit_if_dirty
      connection.should have(1).commits
    end
    
    it 'should commit when commit_if_delete_dirty called on delete_dirty session' do
      @session.remove(Post.new)
      @session.commit_if_delete_dirty
      connection.should have(1).commits
    end
  end

  context 'session proxy' do
    it 'should send messages to manually assigned session proxy' do
      stub_session = stub!('session')
      Sunspot.session = stub_session
      post = Post.new
      stub_session.should_receive(:index).with(post)
      Sunspot.index(post)
      Sunspot.reset!
    end
  end

  def connection
    @connection_factory.instance
  end
end
