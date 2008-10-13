require 'rubygems'
gem 'solr-ruby'
require 'solr'

%w(searchable index fields field_builder).each { |filename| require File.join(File.dirname(__FILE__), 'sunspot', filename) }

module Sunspot
end
