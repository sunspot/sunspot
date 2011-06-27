require File.expand_path('spec_helper', File.join(File.dirname(__FILE__), '..'))

Spec::Runner.configure do |config|
  config.before(:each) do
    Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
  end
end
