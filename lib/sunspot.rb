require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'

%w(adapters condition conditions scope_builder field field_builder indexer query query_builder search type).each do |filename|
  require File.join(File.dirname(__FILE__), 'sunspot', filename)
end

module Sunspot
  VERSION='0.0.1'
end

class <<Sunspot
  def setup(clazz, &block)
    ::Sunspot::FieldBuilder.new(clazz).instance_eval(&block) if block
  end

  def index(*objects)
    for object in objects
      ::Sunspot::Indexer.add(object)
    end
  end

  def search(*types, &block)
    ::Sunspot::Search.new(*types, &block).execute!
  end
end
