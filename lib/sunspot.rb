require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'

%w(condition conditions scope_builder field field_builder indexer query query_builder search searchable type).each { |filename| require File.join(File.dirname(__FILE__), 'sunspot', filename) }

module Sunspot
  VERSION='0.0.1'
end
