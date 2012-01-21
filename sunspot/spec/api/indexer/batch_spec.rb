require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'batch indexing', :type => :indexer do
  let(:posts) { Array.new(2) { |index| Post.new :title => "Post number #{index}!" } }

  it 'should send all batched adds in a single request' do
    session.batch do
      for post in posts
        session.index(post)
      end
    end
    connection.adds.length.should == 1
  end

  it 'should add all batched adds' do
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
    session.batch do
      session.index(posts[0])
      session.remove(posts[1])
    end
    connection.adds
  end

  describe "nesting of batches" do
    let(:a_nested_batch) do
      session.batch do
        session.index posts[0]

        session.batch do
          session.index posts[1]
        end
      end
    end

    it "behaves like two sets of batches, does the inner first, then outer" do
      session.batch { session.index posts[1] }
      session.batch { session.index posts[0] }

      two_sets_of_batches_adds = connection.adds.dup
      connection.adds.clear

      a_nested_batch
      nested_batches_adds = connection.adds

      nested_batches_adds.first.first.field_by_name(:title_ss).value.should eq(
        two_sets_of_batches_adds.first.first.field_by_name(:title_ss).value
      )
    end
  end
end
