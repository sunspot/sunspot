require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'query DSL', :type => :query do
  it 'should allow building search using block argument rather than instance_eval' do
    @blog_id = 1
    session.search Post do |query|
      query.field_list [:blog_id, :title]
      query.with(:blog_id, @blog_id)
    end
    connection.should have_last_search_including(:fq, 'blog_id_i:1')
    connection.should have_last_search_with(fl: [:blog_id, :title])
  end

  it 'should allow field_list specified as arguments' do
    @blog_id = 1
    session.search Post do |query|
      query.field_list :blog_id, :title
      query.with(:blog_id, @blog_id)
    end
    connection.should have_last_search_with(fl: [:blog_id, :title])
  end

  it 'should accept a block in the #new_search method' do
    search = session.new_search(Post) { with(:blog_id, 1) }
    search.execute
    connection.should have_last_search_including(:fq, 'blog_id_i:1')
  end
end
