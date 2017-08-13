require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'search results', :type => :search do
  it 'loads single result' do
    post = Post.new
    stub_results(post)
    expect(session.search(Post).results).to eq([post])
  end

  it 'loads multiple results in order' do
    post_1, post_2 = Post.new, Post.new
    stub_results(post_1, post_2)
    expect(session.search(Post).results).to eq([post_1, post_2])
    stub_results(post_2, post_1)
    expect(session.search(Post).results).to eq([post_2, post_1])
  end

  # This is a reduction of a crazy bug I found in production where some hits
  # were inexplicably not being populated.
  it 'properly loads results of multiple classes that have the same primary key' do
    Post.reset!
    Namespaced::Comment.reset!
    results = [Post.new, Namespaced::Comment.new]
    stub_results(*results)
    expect(session.search(Post, Namespaced::Comment).results).to eq(results)
  end

  it 'gracefully returns empty results when response is nil' do
    stub_nil_results
    expect(session.search(Post).results).to eq([])
  end

  it 'returns search total as attribute of results' do
    stub_results(Post.new, 4)
    expect(session.search(Post) do
      paginate(:page => 1)
    end.results.total_entries).to eq(4)
  end

  it 'returns total' do
    stub_results(Post.new, Post.new, 4)
    expect(session.search(Post) { paginate(:page => 1) }.total).to eq(4)
  end

  it 'returns query time' do
    stub_nil_results
    connection.response['responseHeader'] = { 'QTime' => 42 }
    expect(session.search(Post) { paginate(:page => 1) }.query_time).to eq(42)
  end

  it 'returns total for nil search' do
    stub_nil_results
    expect(session.search(Post).total).to eq(0)
  end

  it 'returns available results if some results are not available from data store' do
    posts = [Post.new, Post.new]
    posts.last.destroy
    stub_results(*posts)
    expect(session.search(Post).results).to eq(posts[0..0])
  end

  it 'does not attempt to query the data store more than once when results are unavailable' do
    posts = [Post.new, Post.new]
    posts.each { |post| post.destroy }
    stub_results(*posts)
    search = session.search(Post) do
      expect(data_accessor_for(Post)).to receive(:load_all).once.and_return([])
    end
    expect(search.results).to eq([])
  end
end
