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
end
