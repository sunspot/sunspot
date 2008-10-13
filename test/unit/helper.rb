require File.join(File.dirname(__FILE__), '..', 'helper')

def lib_require(*args)
  require File.join(File.dirname(__FILE__), '..', '..', 'lib', *args)
end

class Test::Unit::TestCase
  private

  def field(name, options = {})
    @fields ||= {}
    @fields[name] ||= stub "Field: #{name}", { :name => name }.merge(options)
  end

  def post
    @post ||= Post.new
  end
end

class Post
end
