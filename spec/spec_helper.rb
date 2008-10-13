begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'sunspot'

class BaseClass; end

class Post < BaseClass
  include Sunspot::Searchable

  @@id = 0

  attr_reader :id
  attr_accessor :title, :body, :blog_id, :published_at

  def initialize(attrs = {})
    @id = @@id += 1
    attrs.each_pair { |attribute, value| self.send "#{attribute}=", value }
  end

  def category_ids
    @category_ids ||= []
  end

  private
  attr_writer :category_ids
end
