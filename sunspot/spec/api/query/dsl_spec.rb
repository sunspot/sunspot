require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'query DSL', :type => :query do
  let(:blog_id) { 1 }

  it 'should allow building search using block argument rather than instance_eval' do
    session.search Post do |query|
      query.field_list [:blog_id, :title]
      query.with(:blog_id, blog_id)
    end
    expect(connection).to have_last_search_including(:fq, 'blog_id_i:1')
    expect(connection).to have_last_search_with(fl: [:id, :blog_id_i, :title_ss])
  end

  it 'should allow field_list specified as arguments' do
    session.search Post do |query|
      query.field_list :blog_id, :title
      query.with(:blog_id, blog_id)
    end
    expect(connection).to have_last_search_with(fl: [:id, :blog_id_i, :title_ss])
  end

  it 'should allow to skip stored fields retrieval' do
    session.search Post do |query|
      query.with(:blog_id, blog_id)
      query.without_stored_fields
    end
    expect(connection).to have_last_search_with(fl: [:id])
  end

  it 'should accept a block in the #new_search method' do
    search = session.new_search(Post) { with(:blog_id, blog_id) }
    search.execute
    expect(connection).to have_last_search_including(:fq, 'blog_id_i:1')
  end
end
