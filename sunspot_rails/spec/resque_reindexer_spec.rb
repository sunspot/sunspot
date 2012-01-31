require File.expand_path('spec_helper', File.dirname(__FILE__))
describe Sunspot::Rails::ResqueReindexer do
  describe '#perform' do
    it "should call #index on the collection of records with primary key id from start_id to end_id inclusive" do
      post = Post.create!
      Post.should_receive(:find).with(:all,:conditions => ["id between ? and ?", 200, 299]).and_return [post]
      Sunspot.should_receive(:index).with([post])
      Sunspot::Rails::ResqueReindexer.perform("Post", 200, 299)
    end
  end
end