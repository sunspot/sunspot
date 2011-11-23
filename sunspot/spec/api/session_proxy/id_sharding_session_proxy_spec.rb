require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::ShardingSessionProxy do
  before do
    search_session = Sunspot::Session.new
    @sessions = Array.new(2) { Sunspot::Session.new }
    @proxy = Sunspot::SessionProxy::IdShardingSessionProxy.new(search_session, @sessions)
  end

  [:index, :index!, :remove, :remove!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      posts = [Post.new(:id => 2), Post.new(:id => 1)]
      @proxy.sessions[0].should_receive(method).with([posts[0]])
      @proxy.sessions[1].should_receive(method).with([posts[1]])
      @proxy.send(method, posts[0])
      @proxy.send(method, posts[1])
    end
  end

  [:remove_by_id, :remove_by_id!].each do |method|
    it "should delegate #{method} to appropriate session" do
      @proxy.sessions[0].should_receive(method).with(Post, 2)
      @proxy.sessions[1].should_receive(method).with(Post, 1)
      @proxy.send(method, Post, 1)
      @proxy.send(method, Post, 2)
    end
  end

  it_should_behave_like 'session proxy'
end
