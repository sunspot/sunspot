require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Rails::Server do
  before :each do
    @server = Sunspot::Rails::Server.new
    @config = Sunspot::Rails::Configuration.new
    @solr_home = File.join(@config.solr_home)
  end

  it "sets the correct Solr home" do
    @server.solr_home.should == @solr_home
  end

  it "sets the correct Solr library path" do
    @server.lib_path.should == File.join(@solr_home, 'lib')
  end

  it "sets the correct Solr PID path" do
    @server.pid_path.should == File.join(Rails.root, 'tmp', 'pids', 'sunspot-solr-test.pid')
  end

  it "sets the correct Solr data dir" do
    @server.solr_data_dir.should == File.join(@solr_home, 'data', 'test')
  end

  it "sets the correct port" do
    @server.port.should == 8980
  end

  it "sets the correct log level" do
    @server.log_level.should == "FINE"
  end

  it "sets the correct log file" do
    @server.log_file.should == File.join(Rails.root, 'log', 'sunspot-solr-test.log')
  end
end
