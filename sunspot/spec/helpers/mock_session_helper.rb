module MockSessionHelper
  def config
    @config ||= Sunspot::Configuration.build
  end

  def connection
    @connection ||= Mock::Connection.new
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end
end
