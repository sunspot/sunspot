require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('../lib/sunspot/rails/spec_helper', File.dirname(__FILE__))

require 'byebug'

class TbcPostWrong < Post
end

class TbcPostWrongTime < Post
  def collection_postfix
    'hr'
  end
  def time_routed_on
    DateTime.new(2009, 10, 1, 12, 30, 0)
  end
end


describe Sunspot::SessionProxy::TbcSessionProxy, :type => :cloud do
  before :all do
    @config = Sunspot::Configuration.build
    @base_name = @config.collection['base_name']
    @old_session ||= Sunspot.session
  end

  before :each do
    @proxy = Sunspot::SessionProxy::TbcSessionProxy.new(
      date_from: Time.new(2009, 1, 1, 12),
      date_to: Time.new(2010, 1, 1, 12),
      fn_collection_filter: lambda do |collections|
        collections.select { |c| c.end_with?('_hr', '_rt') }
      end
    )
    Sunspot.session = @proxy
  end

  after :all do
    Sunspot.session = @old_session
  end

  it 'simple indexing on wrong object' do
    expect {
      @proxy.index(TbcPostWrong.new(title: 'basic post'))
    }.to raise_error NoMethodError

    expect {
      @proxy.index(TbcPostWrongTime.new(title: 'basic post'))
    }.to raise_error TypeError
  end

  it 'simple indexing on good object' do
    @proxy.index!(Post.create(title: 'basic post'))
  end

  it 'collections shoud contains the current one' do
    post = Post.create(title: 'basic post', created_at: Time.new(2009, 10, 1, 12))
    ts = post.time_routed_on
    @proxy.index!(post)
    c_name = @proxy.send(:collection_name, year: ts.year, month: ts.month)
    ts_start = ts - 1.month
    ts_end = ts + 1.month
    collections = @proxy.send(
      :calculate_search_collections,
      date_from: ts_start,
      date_to: ts_end
    )
    expect(collections).to include("#{c_name}_#{post.collection_postfix}")
  end

  it 'check valid collection for Post' do
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_a")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_b")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_c")
    post = Post.create(title: 'basic post', created_at: Time.new(2009, 10, 1, 12))
    @proxy.index!(post)
    supported = @proxy.calculate_valid_collections(Post)

    expect(supported).to include("#{@base_name}_2009_10_hr")
    expect(supported).not_to include(
      "#{@base_name}_2009_10_a",
      "#{@base_name}_2009_10_b",
      "#{@base_name}_2009_10_c"
    )
  end

  it 'index two documents and retrieve one in hr type collection' do
    @proxy.solr.delete_collection(collection_name: "#{@base_name}_2009_10_hr")
    @proxy.solr.delete_collection(collection_name: "#{@base_name}_2009_10_rt")
    post_a = Post.create(title: 'basic post on Historic', created_at: Time.new(2009, 10, 1, 12))
    post_b = Post.create(title: 'basic post on Realtime', created_at: Time.new(2009, 10, 1, 12))
    post_b.collection_postfix = 'rt'

    @proxy.index!(post_a)
    @proxy.index!(post_b)
    collections = @proxy.send(
      :calculate_search_collections,
      date_from: Time.new(2009, 8),
      date_to: Time.new(2010, 1)
    )

    expect(collections).to include(
      "#{@base_name}_2009_10_hr",
      "#{@base_name}_2009_10_rt"
    )
  end

  it 'index some documents and search for one i a particular collection' do
    # destroy dest collections
    @proxy.solr.delete_collection(collection_name: "#{@base_name}_2009_08_hr")
    @proxy.solr.delete_collection(collection_name: "#{@base_name}_2009_08_rt")

    # create fake collections
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_08_a")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_08_b")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_08_c")

    (1..10).each do |index|
      post = Post.create(
        body: "basic post on Historic #{index}",
        created_at: Time.new(2009, 8, 1, 12)
      )
      @proxy.index(post)
    end
    @proxy.commit

    post = Post.create(body: 'rt simple doc', created_at: Time.new(2009, 8, 1, 12))
    post.collection_postfix = 'rt'
    @proxy.index!(post)

    posts_hr = @proxy.search(Post) { fulltext 'basic post' }
    posts_rt = @proxy.search(Post) { fulltext 'rt simple' }

    expect(posts_hr.hits.size).to eq(10)
    expect(posts_rt.hits.size).to eq(1)
  end

  it 'creates some documents and retrieves it using Post.search method' do
    # create fake collections
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_08_a")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2018_08_rt")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2015_08_hr")

    # creation phase
    (1..10).each do |index|
      post = Post.create(
        body: "basic post on Historic #{index}",
        created_at: Time.new(2009, 8, 1, 12)
      )
      @proxy.index(post)
    end
    @proxy.commit

    # retrieving phase
    posts = Post.search { fulltext 'basic' }
    expect(posts.hits.size).to be >= 10
  end
end
