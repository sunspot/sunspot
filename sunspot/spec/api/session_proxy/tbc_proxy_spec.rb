require File.expand_path('spec_helper', File.dirname(__FILE__))

class TbcPostWrong < Post
end

class TbcPostWrongTime < Post
  def time_routed_on
    Time.new(2009, 10, 1, 12, 30, 0)
  end
end

class TbcPost < Post
  def time_routed_on
    DateTime.new(2009, 10, 1, 12, 30, 0)
  end
end


describe Sunspot::SessionProxy::TbcSessionProxy do
  return unless ENV["SOLR_MODE"] == "cloud"

  before :each do
    Sunspot.session = Sunspot::SessionProxy::TbcSessionProxy.new
  end

  it "simple indexing on wrong object" do
    expect {
      Sunspot.index(TbcPostWrong.new(title: 'basic post'))
    }.to raise_error NoMethodError

    expect {
      Sunspot.index(TbcPostWrongTime.new(title: 'basic post'))
    }.to raise_error TypeError
  end

  it "simple indexing on good object" do
    Sunspot.index!(TbcPost.new(title: 'basic post'))
  end
end