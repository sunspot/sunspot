require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'block join queries' do
  it 'returns the correct children doing a ChildOf query' do
    search = Sunspot.search(Child) do
      child_of(Parent) do
        any_of do
          with(:name, 'Test Parent')
          with(:name, 'Parent')
        end
      end
    end
    expect(search.results).to_not be_empty
  end
end