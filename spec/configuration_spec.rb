require File.dirname(__FILE__) + '/spec_helper'

describe Sunspot::Rails::Configuration, "default values" do
  before(:each) do
    File.should_receive(:exist?).at_least(:once).and_return(false)
    @config = Sunspot::Rails::Configuration.new
  end
  
  it "should handle the 'hostname' property when not set" do
    @config.hostname.should == 'localhost'
  end  
  
  it "should handle the 'path' property when not set" do
    @config.path.should == '/solr'
  end

  it "should handle the 'port' property when not set" do
    @config.port.should == 8983
  end

  it "should handle the 'log_level' property when not set" do
    @config.log_level.should == 'INFO'
  end
  
  it "should handle the 'log_file' property" do
    @config.log_file.should =~ /log\/solr_test.log/
  end
  
  it "should handle the 'solr_home' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.solr_home.should == '/some/path/solr'
  end

  it "should handle the 'data_path' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.data_path.should == '/some/path/solr/data/test'
  end

  it "should handle the 'pid_path' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.pid_path.should == '/some/path/solr/pids/test'
  end
  
  it "should handle the 'solr_home' property when not set" do
    @config.solr_home.should_not == nil
  end

  it "should handle the 'auto_commit_after_request' propery when not set" do
    @config.auto_commit_after_request?.should == true
  end
  
  it "should handle the 'auto_commit_after_delete_request' propery when not set" do
    @config.auto_commit_after_delete_request?.should == false
  end
end

describe Sunspot::Rails::Configuration, "user settings" do
  before(:each) do
    ::Rails.stub!(:env => 'config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'hostname' property when set" do
    @config.hostname.should == 'some.host'
  end

  it "should handle the 'port' property when set" do
    @config.port.should == 1234
  end
  
  it "should handle the 'path' property when set" do
    @config.path.should == '/solr/idx'
  end
  
  it "should handle the 'log_level' propery when set" do
    @config.log_level.should == 'WARNING'
  end
  
  it "should handle the 'solr_home' propery when set" do
    @config.solr_home.should == '/my_superior_path'
  end

  it "should handle the 'data_path' property when set" do
    @config.data_path.should == '/my_superior_path/data'
  end

  it "should handle the 'pid_path' property when set" do
    @config.pid_path.should == '/my_superior_path/pids'
  end
  
  it "should handle the 'solr_home' property when set" do
    @config.solr_home.should == '/my_superior_path'
  end

  it "should handle the 'auto_commit_after_request' propery when set" do
    @config.auto_commit_after_request?.should == false
  end
  
  it "should handle the 'auto_commit_after_delete_request' propery when set" do
    @config.auto_commit_after_delete_request?.should == true
  end
end
