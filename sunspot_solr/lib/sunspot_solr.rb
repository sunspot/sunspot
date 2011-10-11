require 'sunspot/solr/server'

if defined?(Rails) && Rails::VERSION::MAJOR == 3
  require 'sunspot/solr/railtie'
end
