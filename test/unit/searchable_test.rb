require File.join(File.dirname(__FILE__), 'helper')
lib_require 'sunspot', 'searchable'

class SearchableTest < Test::Unit::TestCase
  def test_adds_class_methods
    assert !Post.respond_to?(:configure_search)
    Post.send(:is_searchable)
    assert Post.respond_to?(:configure_search)
  end

  def test_configures_with_block
    field_builder = stub
    field_builder.expects(:string).with(:title)
    ::Sunspot::FieldBuilder.stubs(:new).with(Post).returns field_builder

    Post.is_searchable do
      string :title
    end
  end
end

class Post
  include Sunspot::Searchable
end

module Sunspot
  class FieldBuilder
    def initialize(*args); end
  end
end
