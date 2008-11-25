require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'
require File.join(File.dirname(__FILE__), 'light_config')

%w(adapters condition conditions configuration field field_builder indexer query query_builder scope_builder search type util).each do |filename|
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
      ::Sunspot::Indexer.add(connection, object)
    end
  end

  def search(*types, &block)
    ::Sunspot::Search.new(connection, *types, &block).execute!
  end

  def reset!
    @connection = nil
    @config = nil
  end

  private

  def connection
    @connection ||= Solr::Connection.new(config.solr.url, :autocommit => :on)
  end
end
