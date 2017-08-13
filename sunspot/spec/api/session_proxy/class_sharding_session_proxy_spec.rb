require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::ClassShardingSessionProxy do
  before do
    @proxy = MockClassShardingSessionProxy.new(session)
  end

  [:index, :index!, :remove, :remove!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      post = Post.new
      photo = Photo.new
      expect(@proxy.post_session).to receive(method).with([post])
      expect(@proxy.photo_session).to receive(method).with([photo])
      @proxy.send(method, post)
      @proxy.send(method, photo)
    end
  end

  [:remove_by_id, :remove_by_id!].each do |method|
    it "should delegate #{method} to appropriate shard" do
      expect(@proxy.post_session).to receive(method).with(Post, [1])
      expect(@proxy.photo_session).to receive(method).with(Photo, [1])
      @proxy.send(method, Post, 1)
      @proxy.send(method, Photo, 1)
    end
    it "should delegate #{method} to appropriate shard given ids" do
      expect(@proxy.post_session).to receive(method).with(Post, [1, 2])
      expect(@proxy.photo_session).to receive(method).with(Photo, [1, 2])
      @proxy.send(method, Post, 1, 2)
      @proxy.send(method, Photo, [1, 2])
    end
  end

  [:remove_all, :remove_all!].each do |method|
    it "should delegate #{method} with argument to appropriate shard" do
      expect(@proxy.post_session).to receive(method).with(Post)
      expect(@proxy.photo_session).to receive(method).with(Photo)
      @proxy.send(method, Post)
      @proxy.send(method, Photo)
    end

    it "should delegate #{method} without argument to all shards" do
      expect(@proxy.post_session).to receive(method)
      expect(@proxy.photo_session).to receive(method)
      @proxy.send(method)
    end
  end

  [:commit, :commit_if_dirty, :commit_if_delete_dirty, :optimize].each do |method|
    it "should delegate #{method} to all sessions" do
      [@proxy.post_session, @proxy.photo_session].each do |session|
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
      'http://photos.solr.local/solr,http://posts.solr.local/solr'
    )
  end

  it "should delegate search to search session, adding in shards parameter" do
    @proxy.search(Post)
    expect(connection).to have_last_search_with(
      :shards => 'http://photos.solr.local/solr,http://posts.solr.local/solr'
    )
  end

  [:dirty, :delete_dirty].each do |method|
    it "should be dirty if any of the sessions are dirty" do
      allow(@proxy.post_session).to receive(:"#{method}?").and_return(true)
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
