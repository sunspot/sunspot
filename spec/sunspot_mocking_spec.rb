require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Sunspot Spec Integration - integrate sunspot' do
  integrate_sunspot
  
  it "should call sunspot" do
    Sunspot::Rails.reset
    @post = PostWithAuto.create!
    Sunspot::Rails.session.commit
    PostWithAuto.search.results.should == [@post]
  end
end

describe 'Sunspot Spec Integration - mock sunspot' do
  it "should not call sunspot" do
    Sunspot::Rails.session.remove_all
    Sunspot::Rails.session.commit
    @post = PostWithAuto.create!
    Sunspot::Rails.session.commit
    PostWithAuto.search.results.should_not include(@post)
  end
end
