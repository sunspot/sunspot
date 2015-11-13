require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'atomic updates' do
  before :all do
    Sunspot.remove_all
  end

  def validate_hit(hit, title, featured)
    hit.stored(:title).should == title
    hit.stored(:featured).should == featured
  end

  def find_indexed_post(id)
    hit = Sunspot.search(Post).hits.find{ |h| h.primary_key.to_i == id }
    hit.should_not be_nil
    hit
  end

  it 'should update single record fields one by one' do
    post = Post.new(title: 'A Title', featured: true)
    Sunspot.index!(post)
    
    validate_hit(find_indexed_post(post.id), post.title, post.featured)

    Sunspot.atomic_update!(Post, post.id => {title: 'A New Title'})
    validate_hit(find_indexed_post(post.id), 'A New Title', true)

    Sunspot.atomic_update!(Post, post.id => {featured: false})
    validate_hit(find_indexed_post(post.id), 'A New Title', false)
  end

  it 'should update fields for multiple records' do
    post1 = Post.new(title: 'A First Title', featured: true)
    post2 = Post.new(title: 'A Second Title', featured: false)
    Sunspot.index!(post1, post2)

    validate_hit(find_indexed_post(post1.id), post1.title, post1.featured)
    validate_hit(find_indexed_post(post2.id), post2.title, post2.featured)

    Sunspot.atomic_update!(Post, post1.id => {title: 'A New Title'}, post2.id => {featured: true})
    validate_hit(find_indexed_post(post1.id), 'A New Title', true)
    validate_hit(find_indexed_post(post2.id), 'A Second Title', true)
  end
end
