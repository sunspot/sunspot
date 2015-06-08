module IntegrationHelper
  def self.included(base)
    base.before(:all) do
      Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr/default'
      Sunspot.reset!(true)
    end
  end

  def featured_for_posts(method, param, negated = false)
    with_method = negated ? :without : :with
    param = date_ranges[param] if param.is_a? String

    Sunspot.search(Post) do
      send(with_method, :featured_for).send(method, param)
    end.results
  end
end
