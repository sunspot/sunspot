require 'sunspot/solr/server'

if defined?(Rails) && (3..4).include?(Rails::VERSION::MAJOR)
  require 'sunspot/solr/railtie'
end
