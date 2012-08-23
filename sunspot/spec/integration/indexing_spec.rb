require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'indexing' do
  it 'should index non-multivalued field with newlines' do
    lambda do
      Sunspot.index!(Post.new(:title => "A\nTitle"))
    end.should_not raise_error
  end

  it 'should correctly remove by model instance' do
    post = Post.new(:title => 'test post')
    Sunspot.index!(post)
    Sunspot.remove!(post)
    Sunspot.search(Post) { with(:title, 'test post') }.results.should be_empty
  end

  it 'should correctly delete by ID' do
    post = Post.new(:title => 'test post')
    Sunspot.index!(post)
    Sunspot.remove_by_id!(Post, post.id)
    Sunspot.search(Post) { with(:title, 'test post') }.results.should be_empty
  end

  it 'removes documents by query' do
    Sunspot.remove_all!
    posts = [Post.new(:title => 'birds'), Post.new(:title => 'monkeys')]
    Sunspot.index!(posts)
    Sunspot.remove! do
      with(:title, 'birds')
    end
    Sunspot.search(Post).should have(2).results
  end


  describe "in batches" do
    let(:post_1) { Post.new :title => 'A tittle' }
    let(:post_2) { Post.new :title => 'Another title' }

    describe "nested" do
      let(:a_nested_batch) do
        Sunspot.batch do
          Sunspot.index post_1

          Sunspot.batch do
            Sunspot.index post_2
          end
        end
      end

      it "does not fail" do
        expect { a_nested_batch }.to_not raise_error
      end
    end
  end
end
