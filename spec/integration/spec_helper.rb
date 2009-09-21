require File.join(File.dirname(__FILE__), '..', 'spec_helper')

Spec::Runner.configure do |config|
  config.before(:all) do
    Sunspot.config.solr.url = 'http://localhost:8983/solr'
  end
end
