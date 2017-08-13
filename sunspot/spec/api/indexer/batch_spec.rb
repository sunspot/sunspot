require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'batch indexing', :type => :indexer do
  let(:posts) { Array.new(2) { |index| Post.new :title => "Post number #{index}!" } }

  it 'should send all batched adds in a single request' do
    session.batch do
      for post in posts
        session.index(post)
      end
    end
    expect(connection.adds.length).to eq(1)
  end

  it 'should add all batched adds' do
    session.batch do
      for post in posts
        session.index(post)
      end
    end
    add = connection.adds.last
    expect(connection.adds.first.map { |add| add.field_by_name(:id).value }).to eq(
      posts.map { |post| "Post #{post.id}" }
    )
  end

  it 'should not index changes to models that happen after index call' do
    post = Post.new
    session.batch do
      session.index(post)
      post.title = 'Title'
    end
    expect(connection.adds.first.first.field_by_name(:title_ss)).to be_nil
  end

  it 'should batch an add and a delete' do
    skip 'batching all operations'
    expect(connection).not_to receive(:add)
    expect(connection).not_to receive(:remove)
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

      expect(nested_batches_adds.first.first.field_by_name(:title_ss).value).to eq(
        two_sets_of_batches_adds.first.first.field_by_name(:title_ss).value
      )
    end
  end
end
