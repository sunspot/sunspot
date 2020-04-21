module IndexerHelper
  def post(attrs = {})
    @post ||= Post.new(attrs)
  end

  def last_add
    @connection.adds.last
  end

  def value_in_last_document_for(field_name)
    @connection.adds.last.last.field_by_name(field_name).value
  end

  def values_in_last_document_for(field_name)
    @connection.adds.last.last.fields_by_name(field_name).map { |field| field.value }
  end

  def index_post(post)
    Sunspot.index!(post)
    hit = find_post(post)
    expect(hit).not_to be_nil
    hit
  end

  def find_post(post)
    Sunspot.search(clazz).hits.find { |h| h.primary_key.to_i == post.id && h.id_prefix == id_prefix_value(post, id_prefix) }
  end

  def id_prefix_value(post, id_prefix)
    return unless id_prefix
    return id_prefix if id_prefix.is_a?(String)

    id_prefix.call(post)
  end

  def post_solr_id
    "#{id_prefix_value(post, id_prefix)}#{clazz} #{post.id}"
  end
end
