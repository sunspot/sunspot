require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'

%w(field field_builder indexer type searchable).each { |filename| require File.join(File.dirname(__FILE__), 'sunspot', filename) }

module Sunspot
end
