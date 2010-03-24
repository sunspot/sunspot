module QueryHelper
  def config
    @config ||= Sunspot::Configuration.build
  end

  def connection
    @connection ||= Mock::Connection.new
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end

  def get_filter_tag(boolean_query)
    connection.searches.last[:fq].each do |fq|
      if match = fq.match(/^\{!tag=(.+)\}#{Regexp.escape(boolean_query)}$/)
        return match[1]
      end
    end
    nil
  end
end
