require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::ShardingSessionProxy do
  before do
    @proxy = MockShardingSessionProxy.new(session)
  end

  [:index, :index!, :remove, :remove!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      posts = [Post.new(:blog_id => 2), Post.new(:blog_id => 3)]
      @proxy.sessions[0].should_receive(method).with([posts[0]])
      @proxy.sessions[1].should_receive(method).with([posts[1]])
      @proxy.send(method, posts[0])
      @proxy.send(method, posts[1])
    end
  end

  [:remove_by_id, :remove_by_id!].each do |method|
    it "should raise NotSupportedError when #{method} called" do
      lambda { @proxy.send(method, Post, 1) }.should raise_error(Sunspot::SessionProxy::NotSupportedError)
    end
  end

  [:remove_all, :remove_all!].each do |method|
    it "should raise NotSupportedError when #{method} called with argument" do
      lambda { @proxy.send(method, Post) }.should raise_error(Sunspot::SessionProxy::NotSupportedError)
    end

    it "should delegate #{method} without argument to all shards" do
      @proxy.sessions.each { |session| session.should_receive(method) }
      @proxy.send(method)
    end
  end

  [:commit, :commit_if_dirty, :commit_if_delete_dirty, :optimize].each do |method|
    it "should delegate #{method} to all sessions" do
      @proxy.sessions.each do |session|
        session.should_receive(method)
      end
      @proxy.send(method)
    end
  end

  it "should not support the :batch method" do
    lambda { @proxy.batch }.should raise_error(Sunspot::SessionProxy::NotSupportedError)
  end

  it "should delegate new_search to search session, adding in shards parameter" do
    search = @proxy.new_search(Post)
    search.query[:shards].should ==
      'http://localhost:8980/solr,http://localhost:8981/solr'
  end

  it "should delegate search to search session, adding in shards parameter" do
    @proxy.search(Post)
    connection.should have_last_search_with(
      :shards => 'http://localhost:8980/solr,http://localhost:8981/solr'
    )
  end

  [:dirty, :delete_dirty].each do |method|
    it "should be dirty if any of the sessions are dirty" do
      @proxy.sessions[0].stub!(:"#{method}?").and_return(true)
      @proxy.should send("be_#{method}")
    end

    it "should not be dirty if none of the sessions are dirty" do
      @proxy.should_not send("be_#{method}")
    end
  end

  it "should raise a NotSupportedError when :config is called" do
    lambda { @proxy.config }.should raise_error(Sunspot::SessionProxy::NotSupportedError)
  end

  it_should_behave_like 'session proxy'
end
