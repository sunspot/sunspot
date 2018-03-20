require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'atomic updates' do
  before :all do
    Sunspot.remove_all
  end

  def validate_hit(hit, values = {})
    values.each do |field, value|
      stored = hit.stored(field)
      expect(stored).to eq(value), "expected #{value.inspect}, but got #{stored.inspect} for field '#{field}'"
    end
  end

  def find_indexed_post(id)
    hit = Sunspot.search(Post).hits.find{ |h| h.primary_key.to_i == id }
    expect(hit).not_to be_nil
    hit
  end

  it 'should update single record fields one by one' do
    post = Post.new(title: 'A Title', featured: true)
    Sunspot.index!(post)
    
    validate_hit(find_indexed_post(post.id), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(Post, post.id => {title: 'A New Title'})
    validate_hit(find_indexed_post(post.id), title: 'A New Title', featured: true)

    Sunspot.atomic_update!(Post, post.id => {featured: false})
    validate_hit(find_indexed_post(post.id), title: 'A New Title', featured: false)
  end

  it 'should update fields for multiple records' do
    post1 = Post.new(title: 'A First Title', featured: true)
    post2 = Post.new(title: 'A Second Title', featured: false)
    Sunspot.index!(post1, post2)

    validate_hit(find_indexed_post(post1.id), title: post1.title, featured: post1.featured)
    validate_hit(find_indexed_post(post2.id), title: post2.title, featured: post2.featured)

    Sunspot.atomic_update!(Post, post1.id => {title: 'A New Title'}, post2.id => {featured: true})
    validate_hit(find_indexed_post(post1.id), title: 'A New Title', featured: true)
    validate_hit(find_indexed_post(post2.id), title: 'A Second Title', featured: true)
  end

  it 'should clear field value properly' do
    post = Post.new(title: 'A Title', tags: %w(tag1 tag2), featured: true)
    Sunspot.index!(post)
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: post.tags, featured: true)

    Sunspot.atomic_update!(Post, post.id => {tag_list: []})
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: nil, featured: true)

    Sunspot.atomic_update!(Post, post.id => {featured: nil})
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: nil, featured: nil)
  end
end
