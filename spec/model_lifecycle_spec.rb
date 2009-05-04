require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'searchable with lifecycle' do
  describe 'on create' do
    before :each do
      @post = PostWithAuto.create
      Sunspot.commit
    end

    it 'should automatically index' do
      PostWithAuto.search.results.should == [@post]
    end
  end

  describe 'on update' do
    before :each do
      @post = PostWithAuto.create
      @post.update_attributes(:title => 'Test 1')
      Sunspot.commit
    end

    it 'should automatically update index' do
      PostWithAuto.search { with :title, 'Test 1' }.results.should == [@post]
    end
  end

  describe 'on destroy' do
    before :each do
      @post = PostWithAuto.create
      @post.destroy
      Sunspot.commit
    end

    it 'should automatically remove it from the index' do
      PostWithAuto.search_ids.should be_empty
    end
  end
end
