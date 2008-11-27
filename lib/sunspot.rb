require 'rubygems'
gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'
require File.join(File.dirname(__FILE__), 'light_config')

%w(adapters restriction conditions configuration field field_builder indexer query query_builder scope_builder search session type util).each do |filename|
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
    session.index(*objects)
  end

  def search(*types, &block)
    session.search(*types, &block)
  end

  def config
    session.config
  end

  def reset!
    @session = nil
  end

  private

  def session
    @session ||= ::Sunspot::Session.new
  end
end
