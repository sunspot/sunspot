module IntegrationHelper
  def self.included(base)
    base.before do
      Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
      puts "Expecting Solr to be running at #{Sunspot.config.solr.url}"
    end
  end
end
