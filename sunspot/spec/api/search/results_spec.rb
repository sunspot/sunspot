require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'search results', :type => :search do
  it 'loads single result' do
    post = Post.new
    stub_results(post)
    session.search(Post).results.should == [post]
  end

  it 'loads multiple results in order' do
    post_1, post_2 = Post.new, Post.new
    stub_results(post_1, post_2)
    session.search(Post).results.should == [post_1, post_2]
    stub_results(post_2, post_1)
    session.search(Post).results.should == [post_2, post_1]
  end

  # This is a reduction of a crazy bug I found in production where some hits
  # were inexplicably not being populated.
  it 'properly loads results of multiple classes that have the same primary key' do
    Post.reset!
    Namespaced::Comment.reset!
    results = [Post.new, Namespaced::Comment.new]
    stub_results(*results)
    session.search(Post, Namespaced::Comment).results.should == results
  end

  if ENV['USE_WILL_PAGINATE']

    it 'returns search total as attribute of results' do
      stub_results(Post.new, 4)
      session.search(Post) do
        paginate(:page => 1)
      end.results.total_entries.should == 4
    end

  else

    it 'returns vanilla array if WillPaginate is not available' do
      stub_results(Post.new)
      session.search(Post) do
        paginate(:page => 1)
      end.results.should_not respond_to(:total_entries)
    end

  end

  it 'returns total' do
    stub_results(Post.new, Post.new, 4)
    session.search(Post) { paginate(:page => 1) }.total.should == 4
  end

  it 'returns available results if some results are not available from data store' do
    posts = [Post.new, Post.new]
    posts.last.destroy
    stub_results(*posts)
    session.search(Post).results.should == posts[0..0]
  end

  it 'does not attempt to query the data store more than once when results are unavailable' do
    posts = [Post.new, Post.new]
    posts.each { |post| post.destroy }
    stub_results(*posts)
    search = session.search(Post) do
      data_accessor_for(Post).should_receive(:load_all).once.and_return([])
    end
    search.results.should == []
  end
end
