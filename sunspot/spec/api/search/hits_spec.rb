require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'hits', :type => :search do
  it 'should return hits without loading instances' do
    post_1, post_2 = Array.new(2) { Post.new }
    stub_results(post_1, post_2)
    %w(load load_all).each do |message|
      expect(MockAdapter::DataAccessor).not_to receive(message)
    end
    expect(session.search(Post).hits.map do |hit|
      [hit.class_name, hit.primary_key]
    end).to eq([['Post', post_1.id.to_s], ['Post', post_2.id.to_s]])
  end

  it "should return ID prefix when used with compositeId shard router" do
    Sunspot.index!(ModelWithPrefixId.new)

    expect(Sunspot.search(ModelWithPrefixId).
      hits.map { |h| h.id_prefix }.uniq).to eq ["USERDATA!"]
  end

  it "should parse nested ID prefixes" do
    Sunspot.index!(ModelWithNestedPrefixId.new)

    expect(Sunspot.search(ModelWithNestedPrefixId).
      hits.map { |h| h.id_prefix }.uniq).to eq ["USER!USERDATA!"]
  end

  it 'returns search total as attribute of hits' do
    stub_results(Post.new, 4)
    expect(session.search(Post) do
      paginate(:page => 1)
    end.hits.total_entries).to eq(4)
  end

  it 'returns search total as attribute of verified hits' do
    stub_results(Post.new, 4)
    expect(session.search(Post) do
      paginate(:page => 1)
    end.hits(:verify => true).total_entries).to eq(4)
  end

  it 'should return instance from hit' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    expect(session.search(Post).hits.first.instance).to eq(posts.first)
  end

  it 'should return the instance primary key when you use it as a param' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    expect(session.search(Post).hits.first.to_param).to eq(posts.first.id.to_s)
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

    expect(hits.size).to eq(2)
    expect(results.size).to eq(2)
  end

  it 'should provide an Enumerator over hits with instances' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    search = session.search(Post)
    hits, results = [], []
    search.each_hit_with_result.with_index do |(hit, result), index|
      expect(hit).to be_kind_of(Sunspot::Search::Hit)
      expect(result).to be_kind_of(Post)
      expect(index).to be_kind_of(Integer)
    end
  end

  it 'should hydrate all hits when an instance is requested from a hit' do
    posts = Array.new(2) { Post.new }
    stub_results(*posts)
    search = session.search(Post)
    search.hits.first.instance
    %w(load load_all).each do |message|
      expect(MockAdapter::DataAccessor).not_to receive(message)
    end
    expect(search.hits.last.instance).to eq(posts.last)
  end

  it 'should return only hits whose referenced object exists in the data store if :verify option passed' do
    posts = Array.new(2) { Post.new }
    posts.last.destroy
    stub_results(*posts)
    search = session.search(Post)
    expect(search.hits(:verify => true).map { |hit| hit.instance }).to eq(posts[0..0])
  end

  it 'should return verified and unverified hits from the same search' do
    posts = Array.new(2) { Post.new }
    posts.last.destroy
    stub_results(*posts)
    search = session.search(Post)
    expect(search.hits(:verify => true).map { |hit| hit.instance }).to eq(posts[0..0])
    expect(search.hits.map { |hit| hit.instance }).to eq([posts.first, nil])
  end

  it 'should attach score to hits' do
    stub_full_results('instance' => Post.new, 'score' => 1.23)
    expect(session.search(Post).hits.first.score).to eq(1.23)
  end

  it 'should return stored field values in hits' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    expect(session.search(Post).hits.first.stored(:title)).to eq('Title')
  end

  it 'should return stored field values for searches against multiple types' do
    stub_full_results('instance' => Post.new, 'title_ss' => 'Title')
    expect(session.search(Post, Namespaced::Comment).hits.first.stored(:title)).to eq('Title')
  end

  it 'should return stored field values for searches against base type when subtype matches' do
    class SubclassedPost < Post; end;
    stub_full_results('instance' => SubclassedPost.new, 'title_ss' => 'Title')
    expect(session.search(Post).hits.first.stored(:title)).to eq('Title')
  end

  it 'should return stored text fields' do
    stub_full_results('instance' => Post.new, 'body_textsv' => 'Body')
    expect(session.search(Post, Namespaced::Comment).hits.first.stored(:body)).to eq('Body')
  end

  it 'should return stored boolean fields' do
    stub_full_results('instance' => Post.new, 'featured_bs' => true)
    expect(session.search(Post, Namespaced::Comment).hits.first.stored(:featured)).to be(true)
  end

  it 'should return stored boolean fields that evaluate to false' do
    stub_full_results('instance' => Post.new, 'featured_bs' => false)
    expect(session.search(Post, Namespaced::Comment).hits.first.stored(:featured)).to eq(false)
  end

  it 'should return stored dynamic fields' do
    stub_full_results('instance' => Post.new, 'custom_string:test_ss' => 'Custom')
    expect(session.search(Post, Namespaced::Comment).hits.first.stored(:custom_string, :test)).to eq('Custom')
  end

  it 'should typecast stored field values in hits' do
    time = Time.utc(2008, 7, 8, 2, 45)
    stub_full_results('instance' => Post.new, 'last_indexed_at_ds' => time.xmlschema)
    expect(session.search(Post).hits.first.stored(:last_indexed_at)).to eq(time)
  end

  it 'should return stored values for multi-valued fields' do
    stub_full_results('instance' => User.new, 'role_ids_ims' => %w(1 4 5))
    expect(session.search(User).hits.first.stored(:role_ids)).to eq([1, 4, 5])
  end
end
