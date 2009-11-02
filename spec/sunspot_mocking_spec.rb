require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Sunspot Spec Integration - integrate sunspot' do
  integrate_sunspot
  
  it "should call sunspot" do
    Sunspot::Rails.reset
    @post = PostWithAuto.create!
    Sunspot.commit
    PostWithAuto.search.results.should == [@post]
  end
end

describe 'Sunspot Spec Integration - mock sunspot' do
  it "should call sunspot" do
    Sunspot.remove_all
    Sunspot.commit
    @post = PostWithAuto.create!
    Sunspot.commit
    PostWithAuto.search.results.should_not include(@post)
  end
end
