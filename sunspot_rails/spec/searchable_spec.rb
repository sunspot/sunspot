require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Searchable do
  describe '#searchable' do
    it "should register models with Sunspot.searchable (via Sunspot.setup)" do
    	# Rspec runs tests in random order, causing this test to fail on occasion unless we ensure the models have loaded.
    	Author; Blog; Post;

      expect(Sunspot.searchable).not_to be_empty
      expect(Sunspot.searchable).to include(Author)
      expect(Sunspot.searchable).to include(Blog)
      expect(Sunspot.searchable).to include(Post)
    end
  end
end