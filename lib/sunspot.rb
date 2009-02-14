gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'
require File.join(File.dirname(__FILE__), 'light_config')

%w(adapters builder restriction configuration field indexer query search session type util dsl).each do |filename|
  require File.join(File.dirname(__FILE__), 'sunspot', filename)
end

module Sunspot
  VERSION='0.0.1'
end

class <<Sunspot
  def setup(clazz, &block)
    ::Sunspot::DSL::Fields.new(clazz).instance_eval(&block) if block
  end

  def index(*objects)
    session.index(*objects)
  end

  def search(*types, &block)
    session.search(*types, &block)
  end
  
  def remove(*objects)
    session.remove(*objects)
  end

  def remove_all(*classes)
    session.remove_all(*classes)
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
