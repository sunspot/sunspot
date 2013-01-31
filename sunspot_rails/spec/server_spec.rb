require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Server do
  before :each do
    @server = Sunspot::Rails::Server.new
    @config = Sunspot::Rails::Configuration.new
    @server.stub(:configuration){ @config }
    @solr_home = File.join(@config.solr_home)
  end

  it "sets the correct Solr home" do
    @server.solr_home.should == @solr_home
  end

  it "sets the correct Solr PID path" do
    @server.pid_path.should == File.join(@server.pid_dir, 'sunspot-solr-test.pid')
  end

  it "sets the correct Solr data dir" do
    @server.solr_data_dir.should == File.join(@solr_home, 'data', 'test')
  end

  it "sets the correct port" do
    @server.port.should == 8983
  end

  it "sets the log level using configuration" do
    @config.stub(:log_level){ 'WARNING' }
    @server.log_level.should == "WARNING"
  end

  it "sets the correct log file" do
    @server.log_file.should == File.join(Rails.root, 'log', 'sunspot-solr-test.log')
  end
end
