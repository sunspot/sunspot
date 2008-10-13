require File.join(File.dirname(__FILE__), 'test_helper')

class IndexTest < Test::Unit::TestCase
  def setup
    Solr::Connection.expects(:new).returns connection

    Post.is_searchable do
      # keywords :title, :body
      string :title
      # integer :blog_id
      # integer :category_ids
      # time :published_at
    end
  end

  def test_index_keywords
    post = Post.new :title => 'A Title', :body => 'The Blog Posts here'
    connection.expects(:add).with do |hash|
      assert_equal 'A Title', hash[:title_text]
      assert_equal 'The Blog Posts here', hash[:body_text]
    end
    Sunspot::Index.add post
  end

  private

  def connection
    @connection ||= stub('Connection')
  end
end

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
