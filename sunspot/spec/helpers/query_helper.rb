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

  def subqueries(param)
    q = connection.searches.last[:q]
    subqueries = []
    subqueries = q.scan(%r(_query_:"\{!dismax (.*?)\}(.*?)"))
    subqueries.map do |subquery|
      params = {}
      subquery[0].scan(%r((\S+?)='(.+?)')) do |key, value|
        params[key.to_sym] = value
      end
      unless subquery[1].empty?
        params[:v] = subquery[1]
      end
      params
    end
  end
end
