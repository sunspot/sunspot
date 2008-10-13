require File.join(File.dirname(__FILE__), 'test_helper')
lib_require 'sunspot', 'attribute_field'

class Sunspot::AttributeFieldTest < Test::Unit::TestCase
  def test_pair_for
    assert_equal({ :title_s => 'Indexed: Title' }, attribute_field.pair_for(post))
  end

  private

  def attribute_field(name = :title)
    @attribute_fields ||= {}
    @attribute_fields[name] ||= Sunspot::AttributeField.new(name, StringType)
  end

  def post
    stub 'Post', :title => 'Title'
  end
end

class StringType
  class <<self
    def indexed_name(name)
      "#{name}_s"
    end

    def to_indexed(value)
      "Indexed: " + value.to_s
    end
  end
end
