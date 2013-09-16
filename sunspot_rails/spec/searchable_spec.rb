require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Searchable do
  describe '#searchable' do
    it "should register models with Sunspot.searchable (via Sunspot.setup)" do
    	# Rspec runs tests in random order, causing this test to fail on occasion unless we ensure the models have loaded.
    	Author; Blog; Post;

      Sunspot.searchable.should_not be_empty
      Sunspot.searchable.should include(Author)
      Sunspot.searchable.should include(Blog)
      Sunspot.searchable.should include(Post)
    end
  end
end