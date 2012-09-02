require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Searchable do
  describe '#searchable' do
    it "should register models with Sunspot.searchable (via Sunspot.setup)" do
      Sunspot.searchable.should_not be_empty
      Sunspot.searchable.should include(Author)
      Sunspot.searchable.should include(Blog)
      Sunspot.searchable.should include(Post)
    end
  end
end