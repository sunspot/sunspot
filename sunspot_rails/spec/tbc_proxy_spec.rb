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

class TbcPost < Post
  attr_accessor :collection_postfix

  def collection_postfix
    @collection_postfix || 'hr'
  end

  def time_routed_on
    Time.new(2009, 10, 1, 12, 30, 0)
  end

  def self.select_valid_connection(collections)
    collections.select do |c|
      c.end_with?('_hr', '_rt')
    end
  end
end

describe Sunspot::SessionProxy::TbcSessionProxy do
  return unless ENV['SOLR_MODE'] == 'cloud'

  before :all do
    @config = Sunspot::Configuration.build
    @proxy = Sunspot::SessionProxy::TbcSessionProxy.new(
      date_from: Time.new(2009, 1),
      date_to: Time.new(2010, 1)
    )
    @old_session ||= Sunspot.session
    @base_name = @config.collection['base_name']
    Sunspot.session = @proxy.session
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
    @proxy.index!(TbcPost.new(title: 'basic post'))
  end

  it 'collections shoud contains the current one' do
    post = TbcPost.new(title: 'basic post')
    ts = post.time_routed_on
    @proxy.index!(post)
    c_name = @proxy.send(:collection_name, year: ts.year, month: ts.month)
    collections = @proxy.send(
      :calculate_search_collections,
      date_from: Time.new(2009, 8),
      date_to: Time.new(2010, 1)
    )
    expect(collections.include?("#{c_name}_#{post.collection_postfix}")).to be true
  end

  it 'check valid collection for TbcPost' do
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_a")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_b")
    @proxy.solr.create_collection(collection_name: "#{@base_name}_2009_10_c")
    post = TbcPost.new(title: 'basic post')
    @proxy.index!(post)
    supported = @proxy.calculate_valid_collections(TbcPost)
    expect(supported).to include("#{@base_name}_2009_10_hr")
    expect(supported).not_to include(
      "#{@base_name}_2009_10_a",
      "#{@base_name}_2009_10_b",
      "#{@base_name}_2009_10_c"
    )
  end

  it 'index two documents and retrieve one in hr type collection' do
    post_a = TbcPost.new(title: 'basic post on Historic')
    post_b = TbcPost.new(title: 'basic post on Realtime')
    post_b.collection_postfix = 'rt'

    @proxy.index!([post_a, post_b])
    collections = @proxy.send(
      :calculate_search_collections,
      date_from: Time.new(2009, 8),
      date_to: Time.new(2010, 1)
    ).sort

    expect(collections).to match_array([
      "#{@base_name}_2009_10_hr",
      "#{@base_name}_2009_10_rt"
    ].sort)
  end
end
