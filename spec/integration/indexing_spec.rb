describe 'indexing' do
  it 'should index non-multivalued field with newlines' do
    lambda do
      Sunspot.index!(Post.new(:title => "A\nTitle"))
    end.should_not raise_error(RSolr::RequestError)
  end
end
