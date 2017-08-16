require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::ShardingSessionProxy do
  before do
    @proxy = MockShardingSessionProxy.new(session)
  end

  [:index, :index!, :remove, :remove!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      posts = [Post.new(:blog_id => 2), Post.new(:blog_id => 3)]
      expect(@proxy.sessions[0]).to receive(method).with([posts[0]])
      expect(@proxy.sessions[1]).to receive(method).with([posts[1]])
      @proxy.send(method, posts[0])
      @proxy.send(method, posts[1])
    end
  end

  [:remove_by_id, :remove_by_id!, :atomic_update, :atomic_update!].each do |method|
    it "should raise NotSupportedError when #{method} called" do
      expect { @proxy.send(method, Post, 1) }.to raise_error(Sunspot::SessionProxy::NotSupportedError)
    end
  end

  [:remove_all, :remove_all!].each do |method|
    it "should raise NotSupportedError when #{method} called with argument" do
      expect { @proxy.send(method, Post) }.to raise_error(Sunspot::SessionProxy::NotSupportedError)
    end

    it "should delegate #{method} without argument to all shards" do
      @proxy.sessions.each { |session| expect(session).to receive(method) }
      @proxy.send(method)
    end
  end

  [:commit, :commit_if_dirty, :commit_if_delete_dirty, :optimize].each do |method|
    it "should delegate #{method} to all sessions" do
      @proxy.sessions.each do |session|
        expect(session).to receive(method)
      end
      @proxy.send(method)
    end
  end

  it "should not support the :batch method" do
    expect { @proxy.batch }.to raise_error(Sunspot::SessionProxy::NotSupportedError)
  end

  it "should delegate new_search to search session, adding in shards parameter" do
    search = @proxy.new_search(Post)
    expect(search.query[:shards]).to eq(
      'http://localhost:8980/solr,http://localhost:8981/solr'
    )
  end

  it "should delegate search to search session, adding in shards parameter" do
    @proxy.search(Post)
    expect(connection).to have_last_search_with(
      :shards => 'http://localhost:8980/solr,http://localhost:8981/solr'
    )
  end

  [:dirty, :delete_dirty].each do |method|
    it "should be dirty if any of the sessions are dirty" do
      allow(@proxy.sessions[0]).to receive(:"#{method}?").and_return(true)
      expect(@proxy).to send("be_#{method}")
    end

    it "should not be dirty if none of the sessions are dirty" do
      expect(@proxy).not_to send("be_#{method}")
    end
  end

  it "should raise a NotSupportedError when :config is called" do
    expect { @proxy.config }.to raise_error(Sunspot::SessionProxy::NotSupportedError)
  end

  it_should_behave_like 'session proxy'
end
