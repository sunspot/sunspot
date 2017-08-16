require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'indexing fixed fields', :type => :indexer do
  it 'should index id' do
    session.index post
    expect(connection).to have_add_with(:id => "Post #{post.id}")
  end

  it 'should index type' do
    session.index post
    expect(connection).to have_add_with(:type => ['Post', 'SuperClass', 'MockRecord'])
  end

  it 'should not index join fields' do
    session.index PhotoContainer.new
    expect(connection).not_to have_add_with(:photo_caption => 'blah')
  end

  it 'should index class name' do
    session.index post
    expect(connection).to have_add_with(:class_name => 'Post')
  end

  it 'should index the array of objects supplied' do
    posts = Array.new(2) { Post.new }
    session.index posts
    expect(connection).to have_add_with(
      { :id => "Post #{posts.first.id}" },
      { :id => "Post #{posts.last.id}" }
    )
  end

  it 'should index an array containing more than one type of object' do
    post1, comment, post2 = objects = [Post.new, Namespaced::Comment.new, Post.new]
    session.index objects
    expect(connection).to have_add_with(
      { :id => "Post #{post1.id}", :type => ['Post', 'SuperClass', 'MockRecord'] },
      { :id => "Namespaced::Comment #{comment.id}", :type => ['Namespaced::Comment', 'MockRecord'] },
      { :id => "Post #{post2.id}", :type => ['Post', 'SuperClass', 'MockRecord'] }
    )
  end

  it 'commits immediately after index! called' do
    expect(connection).to receive(:add).ordered
    expect(connection).to receive(:commit).ordered
    session.index!(post)
  end

  it 'raises an ArgumentError if an attempt is made to index an object that has no configuration' do
    expect { session.index(Blog.new) }.to raise_error(Sunspot::NoSetupError)
  end

  it 'raises a NoAdapterError if class without adapter is indexed' do
    expect { session.index(User.new) }.to raise_error(Sunspot::NoAdapterError)
  end

  it 'raises an ArgumentError if a non-word character is included in the field name' do
    expect do
      Sunspot.setup(Post) { string :"bad name" }
    end.to raise_error(ArgumentError)
  end
end
