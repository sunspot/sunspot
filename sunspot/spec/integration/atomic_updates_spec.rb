require File.expand_path('../spec_helper', File.dirname(__FILE__))

shared_examples 'atomic update with instance as key' do
  it 'updates record' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(clazz, post => { title: 'A New Title' })
    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A New Title', featured: true)

    Sunspot.atomic_update!(clazz, post => { featured: false })
    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A New Title', featured: false)
  end

  it 'does not print warning' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    expect do
      Sunspot.atomic_update!(clazz, post => { title: 'A New Title' })
    end.to_not output(Sunspot::AtomicUpdateRequireInstanceForCompositeIdMessage.call(clazz)).to_stderr
  end

  it 'does not create duplicate document' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(clazz, post => { title: 'A New Title' })
    hit = find_indexed_post_with_prefix_id(post, nil)
    expect(hit).to be_nil
  end
end

shared_examples 'atomic update with id as key' do
  it 'does not update record' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A Title', featured: true)

    Sunspot.atomic_update!(clazz, post.id => { featured: false })
    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A Title', featured: true)
  end

  it 'prints warning' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    expect do
      Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
    end.to output(Sunspot::AtomicUpdateRequireInstanceForCompositeIdMessage.call(clazz) + "\n").to_stderr
  end

  it 'creates duplicate document that have only fields provided for update' do
    post = clazz.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
    validate_hit(find_and_validate_indexed_post_with_prefix_id(post, nil), title: 'A New Title', featured: nil)
  end
end

describe 'Atomic Update feature' do
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

  def find_and_validate_indexed_post_with_prefix_id(post, id_prefix)
    hit = find_indexed_post_with_prefix_id(post, id_prefix_value(post, id_prefix))
    expect(hit).not_to be_nil
    hit
  end

  def find_indexed_post_with_prefix_id(post, id_prefix)
    Sunspot.search(post.class).hits.find { |h| h.primary_key.to_i == post.id && h.id_prefix == id_prefix }
  end

  def id_prefix_value(post, id_prefix)
    return unless id_prefix
    return id_prefix if id_prefix.is_a?(String)

    id_prefix.call(post)
  end

  it 'updates single record fields one by one' do
    post = Post.new(title: 'A Title', featured: true)
    Sunspot.index!(post)

    validate_hit(find_indexed_post(post.id), title: post.title, featured: post.featured)

    Sunspot.atomic_update!(Post, post.id => {title: 'A New Title'})
    validate_hit(find_indexed_post(post.id), title: 'A New Title', featured: true)

    Sunspot.atomic_update!(Post, post.id => {featured: false})
    validate_hit(find_indexed_post(post.id), title: 'A New Title', featured: false)
  end

  it 'updates fields for multiple records' do
    post1 = Post.new(title: 'A First Title', featured: true)
    post2 = Post.new(title: 'A Second Title', featured: false)
    Sunspot.index!(post1, post2)

    validate_hit(find_indexed_post(post1.id), title: post1.title, featured: post1.featured)
    validate_hit(find_indexed_post(post2.id), title: post2.title, featured: post2.featured)

    Sunspot.atomic_update!(Post, post1.id => {title: 'A New Title'}, post2.id => {featured: true})
    validate_hit(find_indexed_post(post1.id), title: 'A New Title', featured: true)
    validate_hit(find_indexed_post(post2.id), title: 'A Second Title', featured: true)
  end

  it 'sets array value' do
    post = Post.new(title: 'A Title', tags: %w(tag1 tag2))
    Sunspot.index!(post)
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: post.tags)

    updated_array = %w(tag3 tag4)
    Sunspot.atomic_update!(Post, post.id => { tag_list: updated_array })
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: updated_array)
  end

  it 'clears field value properly' do
    post = Post.new(title: 'A Title', tags: %w(tag1 tag2), featured: true)
    Sunspot.index!(post)
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: post.tags, featured: true)

    Sunspot.atomic_update!(Post, post.id => {tag_list: []})
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: nil, featured: true)

    Sunspot.atomic_update!(Post, post.id => {featured: nil})
    validate_hit(find_indexed_post(post.id), title: post.title, tag_list: nil, featured: nil)
  end

  context 'when `id_prefix` is defined on model' do
    context 'as Proc' do
      let(:clazz) { PostWithProcPrefixId }
      let(:id_prefix) { lambda { |post| "USERDATA-#{post.id}!" } }

      context 'and instance passed as key' do
        include_examples 'atomic update with instance as key'
      end

      context 'and id passed as key' do
        include_examples 'atomic update with id as key'
      end
    end

    context 'as Symbol' do
      let(:clazz) { PostWithSymbolPrefixId }
      let(:id_prefix) { lambda { |post| "#{post.title}!" } }

      context 'and instance passed as key' do
        include_examples 'atomic update with instance as key'
      end

      context 'and id passed as key' do
        include_examples 'atomic update with id as key'
      end
    end

    context 'as String' do
      let(:clazz) { PostWithStringPrefixId }
      let(:id_prefix) { 'USERDATA!' }

      context 'and instance passed as key' do
        include_examples 'atomic update with instance as key'
      end

      context 'and id passed as key' do
        it 'updates record' do
          post = clazz.new(title: 'A Title', featured: true)
          Sunspot.index!(post)

          validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

          Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
          validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A New Title', featured: true)

          Sunspot.atomic_update!(clazz, post.id => { featured: false })
          validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: 'A New Title', featured: false)
        end

        it 'does not print warning' do
          post = clazz.new(title: 'A Title', featured: true)
          Sunspot.index!(post)

          validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

          expect do
            Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
          end.to_not output(Sunspot::AtomicUpdateRequireInstanceForCompositeIdMessage.call(clazz) + "\n").to_stderr
        end

        it 'does not create duplicate document' do
          post = clazz.new(title: 'A Title', featured: true)
          Sunspot.index!(post)

          validate_hit(find_and_validate_indexed_post_with_prefix_id(post, id_prefix), title: post.title, featured: post.featured)

          Sunspot.atomic_update!(clazz, post.id => { title: 'A New Title' })
          hit = find_indexed_post_with_prefix_id(post, nil)
          expect(hit).to be_nil
        end
      end
    end
  end
end
