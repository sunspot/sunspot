require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::ClassShardingSessionProxy do
  before do
    @proxy = MockClassShardingSessionProxy.new(session)
  end

  [:index, :index!, :remove, :remove!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      post = Post.new
      photo = Photo.new
      @proxy.post_session.should_receive(method).with([post])
      @proxy.photo_session.should_receive(method).with([photo])
      @proxy.send(method, post)
      @proxy.send(method, photo)
    end
  end

  [:remove_by_id, :remove_by_id!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      @proxy.post_session.should_receive(method).with(Post, 1)
      @proxy.photo_session.should_receive(method).with(Photo, 1)
      @proxy.send(method, Post, 1)
      @proxy.send(method, Photo, 1)
    end
  end

  [:remove_all, :remove_all!].each do |method|
    it "should delegate #{method} with argument to appropriate shard" do
      @proxy.post_session.should_receive(method).with(Post)
      @proxy.photo_session.should_receive(method).with(Photo)
      @proxy.send(method, Post)
      @proxy.send(method, Photo)
    end

    it "should delegate #{method} without argument to all shards" do
      @proxy.post_session.should_receive(method)
      @proxy.photo_session.should_receive(method)
      @proxy.send(method)
    end
  end

  [:commit, :commit_if_dirty, :commit_if_delete_dirty, :optimize].each do |method|
    it "should delegate #{method} to all sessions" do
      [@proxy.post_session, @proxy.photo_session].each do |session|
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
      'http://photos.solr.local/solr,http://posts.solr.local/solr'
  end

  it "should delegate search to search session, adding in shards parameter" do
    @proxy.search(Post)
    connection.should have_last_search_with(
      :shards => 'http://photos.solr.local/solr,http://posts.solr.local/solr'
    )
  end

  [:dirty, :delete_dirty].each do |method|
    it "should be dirty if any of the sessions are dirty" do
      @proxy.post_session.stub!(:"#{method}?").and_return(true)
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
