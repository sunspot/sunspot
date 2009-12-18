class MockShardingSessionProxy < Sunspot::SessionProxy::ShardingSessionProxy
  attr_reader :sessions
  alias_method :all_sessions, :sessions

  def initialize(search_session)
    super
    @sessions = Array.new(2) { Sunspot::Session.new }.each_with_index do |session, i|
      session.config.solr.url = "http://localhost:898#{i}/solr"
    end
  end

  def session_for(object)
    @sessions[object.blog_id.to_i % 2]
  end
end
