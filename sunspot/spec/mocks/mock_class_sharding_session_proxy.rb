class MockClassShardingSessionProxy < Sunspot::SessionProxy::ClassShardingSessionProxy
  attr_reader :post_session, :photo_session

  def initialize(search_session)
    super
    @post_session, @photo_session = Sunspot::Session.new, Sunspot::Session.new
    @post_session.config.solr.url = 'http://posts.solr.local/solr'
    @photo_session.config.solr.url = 'http://photos.solr.local/solr'
    @sessions = {
      Post => @post_session,
      Photo => @photo_session
    }
  end

  def session_for_class(clazz)
    @sessions[clazz]
  end

  def all_sessions
    @sessions.values.sort do |lsession, rsession|
      lsession.config.solr.url <=> rsession.config.solr.url
    end
  end
end
