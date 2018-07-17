require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'block join queries' do
  it 'returns the correct children doing a ChildOf query' do
    search = Sunspot.search(Child) do
      child_of(Parent) do
        with :name, 'Test Parent'
      end
    end
    expect(search.results).to_not be_empty
  end
end