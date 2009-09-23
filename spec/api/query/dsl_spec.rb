require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'query DSL', :type => :query do
  it 'should allow building search using block argument rather than instance_eval' do
    @blog_id = 1
    session.search Post do |query|
      query.with(:blog_id, @blog_id)
    end
    connection.should have_last_search_including(:fq, 'blog_id_i:1')
  end
end

