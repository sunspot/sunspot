module IntegrationHelper
  def self.included(base)
    base.before(:all) do
      Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
      Sunspot.reset!(true)
    end
  end
end
