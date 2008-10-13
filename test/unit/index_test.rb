require File.join(File.dirname(__FILE__), 'test_helper')
lib_require 'sunspot', 'index'

class IndexTest < Test::Unit::TestCase
  def test_add
    Sunspot::Index::Indexer.expects(:add).with post
    Sunspot::Index.add(post)
  end

  private

  def post
    @post ||= Post.new
  end
end

class Post
end
