describe 'typed query' do
  it 'properly escapes namespaced type names' do
    session.search(Namespaced::Comment)
    expect(connection).to have_last_search_with(:fq => ['type:Namespaced\:\:Comment'])
  end

  it 'builds search for multiple types' do
    session.search(Post, Namespaced::Comment)
    expect(connection).to have_last_search_with(:fq => ['type:(Post OR Namespaced\:\:Comment)'])
  end

  it 'searches type of subclass when superclass is configured' do
    session.search PhotoPost
    expect(connection).to have_last_search_with(:fq => ['type:PhotoPost'])
  end

  it 'raises an ArgumentError if no types given to search' do
    expect { session.search }.to raise_error(ArgumentError)
  end
end
