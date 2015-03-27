module IntegrationHelper
  def self.included(base)
    base.before(:all) do
      Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr/default'
      Sunspot.reset!(true)
    end
  end

  def featured_for_posts(method, param)
    param = date_ranges[param] if param.is_a? String
    Sunspot.search(Post) do
      with(:featured_for).send(method, param)
    end.results
  end
end
