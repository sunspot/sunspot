require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'hits', :type => :search do
  it 'should return hits without loading instances' do
    post_1, post_2 = Array.new(2) { Post.new }
    stub_results(post_1, post_2)
    %w(load load_all).each do |message|
      MockAdapter::DataAccessor.should_not_receive(message)
    end
    session.search(Post).hits.map do |hit|
      [hit.class_name, hit.primary_key]
    end.should == [['Post', post_1.id.to_s], ['Post', post_2.id.to_s]]
  end

  if ENV['USE_WILL_PAGINATE']

    it 'returns search total as attribute of hits' do
      stub_results(Post.new, 4)
      session.search(Post) do
        paginate(:page => 1)
      end.hits.total_entries.should == 4
    end

    it 'returns search total as attribute of verified hits' do
      stub_results(Post.new, 4)
      session.search(Post) do
        paginate(:page => 1)
      end.hits(:verify => true).total_entries.should == 4
    end

  else

    it 'returns vanilla array of hits if WillPaginate is not available' do
      stub_results(Post.new)
      session.search(Post) do
        paginate(:page => 1)
      end.hits.should_not respond_to(:total_entries)
    end

    it 'returns vanilla array of verified hits if WillPaginate is not available' do
      stub_results(Post.new)
      session.search(Post) do
        paginate(:page => 1)
      end.hits(:verified => true).should_not respond_to(:total_entries)
    end

  end

  it 'should return instance from hit' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    session.search(Post).hits.first.instance.should == posts.first
  end

  it 'should provide iterator over hits with instances' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    search = session.search(Post)
    hits, results = [], []
    search.each_hit_with_result do |hit, result|
      hits << hit
      results << result
    end
  end

  it 'should hydrate all hits when an instance is requested from a hit' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    search = session.search(Post)
    search.hits.first.instance
    %w(load load_all).each do |message|
      MockAdapter::DataAccessor.should_not_receive(message)
    end
    search.hits.last.instance.should == posts.last
  end

  it 'should return only hits whose referenced object exists in the data store if :verify option passed' do
    posts = Array.new(2) { Post.new }
    posts.last.destroy
    stub_results(*posts)
    search = session.search(Post)
    search.hits(:verify => true).map { |hit| hit.instance }.should == posts[0..0]
  end

  it 'should return verified and unverified hits from the same search' do
    posts = Array.new(2) { Post.new }
    posts.last.destroy
    stub_results(*posts)
    search = session.search(Post)
    search.hits(:verify => true).map { |hit| hit.instance }.should == posts[0..0]
    search.hits.map { |hit| hit.instance }.should == [posts.first, nil]
  end

  it 'should attach score to hits' do
    stub_full_results('instance' => Post.new, 'score' => 1.23)
    session.search(Post).hits.first.score.should == 1.23
  end

  it 'should return stored field values in hits' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    session.search(Post).hits.first.stored(:title).should == 'Title'
  end

  it 'should return stored field values for searches against multiple types' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    session.search(Post, Namespaced::Comment).hits.first.stored(:title).should == 'Title'
  end

  it 'should return stored text fields' do
    stub_full_results('instance' => Post.new, 'body_textsv' => 'Body')
    session.search(Post, Namespaced::Comment).hits.first.stored(:body).should == 'Body'
  end

  it 'should return stored dynamic fields' do
    stub_full_results('instance' => Post.new, 'custom_string:test_ss' => 'Custom')
    session.search(Post, Namespaced::Comment).hits.first.stored(:custom_string, :test).should == 'Custom'
  end

  it 'should typecast stored field values in hits' do
    time = Time.utc(2008, 7, 8, 2, 45)
    stub_full_results('instance' => Post.new, 'last_indexed_at_ds' => time.xmlschema)
    session.search(Post).hits.first.stored(:last_indexed_at).should == time
  end

  it 'should return geo distance' do
    post = Post.new
    stub_results(post)
    connection.response['distances'] = {
      "Post #{post.id}" => 1.23
    }
    session.search(Post).hits.first.distance.should == 1.23
  end

  it 'should return nil if no geo distance' do
    stub_results(Post.new)
    session.search(Post).hits.first.distance.should be_nil
  end
end
