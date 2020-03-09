require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'document removal', :type => :indexer do
  it 'removes an object from the index' do
    session.remove(post)
    expect(connection).to have_delete("Post #{post.id}")
  end

  it 'removes an object by type and id' do
    session.remove_by_id(Post, 1)
    expect(connection).to have_delete('Post 1')
  end

  it 'removes an object by type and ids' do
    session.remove_by_id(Post, 1, 2)
    expect(connection).to have_delete('Post 1', 'Post 2')
  end

  it 'removes an object by type and ids array' do
    session.remove_by_id(Post, [1, 2])
    expect(connection).to have_delete('Post 1', 'Post 2')
  end

  it 'removes an object by type and ids and immediately commits' do
    expect(connection).to receive(:delete_by_id).with(['Post 1', 'Post 2', 'Post 3']).ordered
    expect(connection).to receive(:commit).ordered
    session.remove_by_id!(Post, 1, 2, 3)
  end

  it 'removes an object from the index and immediately commits' do
    expect(connection).to receive(:delete_by_id).ordered
    expect(connection).to receive(:commit).ordered
    session.remove!(post)
  end

  it 'removes everything from the index' do
    session.remove_all
    expect(connection).to have_delete_by_query("*:*")
  end

  it 'removes everything from the index and immediately commits' do
    expect(connection).to receive(:delete_by_query).ordered
    expect(connection).to receive(:commit).ordered
    session.remove_all!
  end

  it 'removes everything of a given class from the index' do
    session.remove_all(Post)
    expect(connection).to have_delete_by_query("type:Post")
  end

  it 'correctly escapes namespaced classes when removing everything from the index' do
    expect(connection).to receive(:delete_by_query).with('type:Namespaced\:\:Comment')
    session.remove_all(Namespaced::Comment)
  end

  it 'should remove by query' do
    session.remove(Post) do
      with(:title, 'monkeys')
    end
    expect(connection).to have_delete_by_query("(type:Post AND title_ss:monkeys)")
  end

  context 'when call #remove_by_id' do
    let(:post) { clazz.new(title: 'A Title') }
    before(:each) { index_post(post) }

    context 'and `id_prefix` is defined on model' do
      context 'as Proc' do
        let(:clazz) { PostWithProcPrefixId }
        let(:id_prefix) { lambda { |post| "USERDATA-#{post.id}!" } }

        it 'prints warning' do
          expect do
            session.remove_by_id(clazz, post.id)
          end.to output(Sunspot::RemoveByIdNotSupportCompositeIdMessage.call(clazz) + "\n").to_stderr
        end

        it 'does not remove record' do
          session.remove_by_id(clazz, post.id)
          expect(connection).to have_no_delete(post_solr_id)
        end
      end

      context 'as Symbol' do
        let(:clazz) { PostWithSymbolPrefixId }
        let(:id_prefix) { lambda { |post| "#{post.title}!" } }

        it 'prints warning' do
          expect do
            session.remove_by_id(clazz, post.id)
          end.to output(Sunspot::RemoveByIdNotSupportCompositeIdMessage.call(clazz) + "\n").to_stderr
        end

        it 'does not remove record' do
          session.remove_by_id(clazz, post.id)
          expect(connection).to have_no_delete(post_solr_id)
        end
      end

      context 'as String' do
        let(:clazz) { PostWithStringPrefixId }
        let(:id_prefix) { 'USERDATA!' }

        it 'does not print warning' do
          expect do
            session.remove_by_id(clazz, post.id)
          end.to_not output(Sunspot::RemoveByIdNotSupportCompositeIdMessage.call(clazz) + "\n").to_stderr
        end

        it 'removes record' do
          session.remove_by_id(clazz, post.id)
          expect(connection).to have_delete(post_solr_id)
        end
      end
    end

    context 'and `id_prefix` is not defined on model' do
      let(:clazz) { PostWithoutPrefixId }
      let(:id_prefix) { nil }

      it 'does not print warning' do
        expect do
          session.remove_by_id(clazz, post.id)
        end.to_not output(Sunspot::RemoveByIdNotSupportCompositeIdMessage.call(clazz) + "\n").to_stderr
      end

      it 'removes record' do
        session.remove_by_id(clazz, post.id)
        expect(connection).to have_delete(post_solr_id)
      end
    end
  end
end
