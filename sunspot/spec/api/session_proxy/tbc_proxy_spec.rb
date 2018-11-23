require File.expand_path('spec_helper', File.dirname(__FILE__))

class TbcPost < Post
end

describe Sunspot::SessionProxy::TbcSessionProxy do
  # before :each do
  #   Sunspot.session = Sunspot::SessionProxy::TbcSessionProxy.new
  # end

  # it "simple indexing" do
  #   Sunspot.index(TbcPost.new(title: 'basic post'))
  # end
end