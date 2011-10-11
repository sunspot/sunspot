module QueryHelper
  def get_filter_tag(boolean_query)
    connection.searches.last[:fq].each do |fq|
      if match = fq.match(/^\{!tag=(.+)\}#{Regexp.escape(boolean_query)}$/)
        return match[1]
      end
    end
    nil
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
