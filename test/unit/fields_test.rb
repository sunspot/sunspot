require File.join(File.dirname(__FILE__), 'helper')
lib_require 'sunspot', 'fields'

class FieldsTest < Test::Unit::TestCase
  def test_for
    Sunspot::Fields.add(Post, [field('name'), field('body')])
    assert_equal [field('name'), field('body')], Sunspot::Fields.for(Post)
  end

  def test_for_nonexistent
    assert_equal [], Sunspot::Fields.for(Comment)
  end
end

class Comment; end
