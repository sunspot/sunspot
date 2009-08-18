require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'batch indexing', :type => :indexer do
  it 'should send all batched adds in a single request' do
    posts = Array.new(2) { Post.new }
    session.batch do
      for post in posts
        session.index(post)
      end
    end
    connection.adds.length.should == 1
  end

  it 'should add all batched adds' do
    posts = Array.new(2) { Post.new }
    session.batch do
      for post in posts
        session.index(post)
      end
    end
    add = connection.adds.last
    connection.adds.first.map { |add| add.field_by_name(:id).value }.should ==
      posts.map { |post| "Post #{post.id}" }
  end

  it 'should not index changes to models that happen after index call' do
    post = Post.new
    session.batch do
      session.index(post)
      post.title = 'Title'
    end
    connection.adds.first.first.field_by_name(:title_ss).should be_nil
  end

  it 'should batch an add and a delete' do
    pending 'batching all operations'
    connection.should_not_receive(:add)
    connection.should_not_receive(:remove)
    posts = Array.new(2) { Post.new }
    session.batch do
      session.index(posts[0])
      session.remove(posts[1])
    end
    connection.adds
  end
end
