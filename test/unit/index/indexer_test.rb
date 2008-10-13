require File.join(File.dirname(__FILE__), '..', 'helper')
lib_require 'sunspot', 'index', 'indexer'

class IndexerTest < Test::Unit::TestCase
  def test_add
    Sunspot::Index::Indexer.stubs(:for).with(Post).returns indexer
    indexer.expects(:add).with post
    Sunspot::Index::Indexer.add post
  end

  def test_for
    Sunspot::Fields.stubs(:for).with(Post).returns [field('title'), field('body')]
    Sunspot::Fields.stubs(:for).with(PhotoPost).returns [field('caption')]
    assert_equal [field('title'), field('body')].sort_by { |f| f.name }, Sunspot::Index::Indexer.for(Post).fields.sort_by { |f| f.name }
    assert_equal [field('title'), field('body'), field('caption')].sort_by { |f| f.name }, Sunspot::Index::Indexer.for(PhotoPost).fields.sort_by { |f| f.name }
  end

  def test_fields
    indexer = Sunspot::Index::Indexer.new(stub('Connection'))
    indexer.add_fields [field('title'), field('body')] 
    assert indexer.fields.include?(field('title')), 'expected fields to include title'
    assert indexer.fields.include?(field('body')), 'expected fields to include body'
  end

  def test_add
    field('name').stubs(:pair_for).with(post).returns(:name_s => 'Post')
    post.stubs(:id).returns 1
    connection.expects(:add).with(:id => 'Post:1', :type => ['Post'], :name_s => 'Post')
    indexer = Sunspot::Index::Indexer.new(connection)
    indexer.add_fields [field('name')]
    indexer.add post
  end

  private

  def connection
    @connection ||= stub('Connection')
  end

  def indexer
    @indexer ||= stub('Indexer') do |indexer|
      indexer.stubs(:add)
    end
  end
end

module Sunspot
  module Fields
  end

  class FieldValue
  end
end

class PhotoPost < Post
end

class Solr
  class Connection
    def initialize(str, bool = false)
    end
  end
end
