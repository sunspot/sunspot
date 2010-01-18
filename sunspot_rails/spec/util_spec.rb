require File.dirname(__FILE__) + '/spec_helper'

describe 'ActiveRecord mixin and instance methods' do
  it "should know about relevant index attributes - relevant attribute changed" do
    @post = PostWithAuto.new
    @post.should_receive(:changes).and_return(:title => 'new title')
    Sunspot::Rails::Util.index_relevant_attribute_changed?(@post).should == true
  end

  it "should know about relevant index attributes - no relevant attribute changed" do
    @post = PostWithAuto.new
    @post.should_receive(:changes).and_return(:updated_at => Date.tomorrow)
    Sunspot::Rails::Util.index_relevant_attribute_changed?(@post).should == false
  end
end
