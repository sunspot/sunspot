require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

Spec::Runner.configure do |config|
  config.before(:each) do
    Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
  end
end
