require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Rails::Configuration, "default values" do
  before(:each) do
    File.should_receive(:exist?).and_return(false)
  end
  
  it "should handle the 'hostname' property when not set" do
    config = Sunspot::Rails::Configuration.new
    config.hostname.should == 'localhost'
  end  
  
  it "should handle the 'path' property when not set" do
    config = Sunspot::Rails::Configuration.new
    config.path.should == '/solr'
  end

  it "should handle the 'port' property when not set" do
    config = Sunspot::Rails::Configuration.new
    config.port.should == 8983
  end

  it "should handle the 'auto_commit_after_request' propery when not set" do
    config = Sunspot::Rails::Configuration.new
    config.auto_commit_after_request?.should == true
  end
end

describe Sunspot::Rails::Configuration, "user settings" do
  before(:each) do
    Rails.stub!(:env => 'config_test')
  end

  it "should handle the 'hostname' property when not set" do
    config = Sunspot::Rails::Configuration.new
    config.hostname.should == 'some.host'
  end

  it "should handle the 'port' property when not set" do
    config = Sunspot::Rails::Configuration.new
    config.port.should == 1234
  end
  
  it "should handle the 'path' property when set" do
    config = Sunspot::Rails::Configuration.new
    config.path.should == '/solr/idx'
  end

  it "should handle the 'auto_commit_after_request' propery when set" do
    config = Sunspot::Rails::Configuration.new
    config.auto_commit_after_request?.should == false
  end
end
