require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Search do
  it 'should allow access to the data accessor' do
    stub_results(posts = Post.new)
    search = session.search Post do
      data_accessor_for(Post).custom_title = 'custom title'
    end
    search.results.first.title.should == 'custom title'
  end
end
