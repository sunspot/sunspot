require File.dirname(__FILE__) + '/spec_helper'

describe 'searchable with lifecycle' do
  integrate_sunspot
  
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

describe 'searchable with lifecycle - ignoring specific attributes' do
  integrate_sunspot
  
  before(:each) do
    @post = PostWithAuto.create
  end
  
  it "should not reindex the object on an update_at change, because it is marked as to-ignore" do
    Sunspot.should_not_receive(:index).with(@post)
    @post.update_attribute :updated_at, 123.seconds.from_now
  end
end
