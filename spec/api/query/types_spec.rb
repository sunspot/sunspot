describe 'typed query' do
  it 'properly escapes namespaced type names' do
    session.search(Namespaced::Comment)
    connection.should have_last_search_with(:q => 'type:Namespaced\:\:Comment')
  end

  it 'builds search for multiple types' do
    session.search(Post, Namespaced::Comment)
    connection.should have_last_search_with(:q => 'type:(Post OR Namespaced\:\:Comment)')
  end

  it 'raises an ArgumentError if no types given to search' do
    lambda { session.search }.should raise_error(ArgumentError)
  end
end
