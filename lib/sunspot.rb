require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'

%w(attribute_field field_builder fields index type searchable).each { |filename| require File.join(File.dirname(__FILE__), 'sunspot', filename) }

module Sunspot
end
