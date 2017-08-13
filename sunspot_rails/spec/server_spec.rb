require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Server do
  before :each do
    @server = Sunspot::Rails::Server.new
    @config = Sunspot::Rails::Configuration.new
    allow(@server).to receive(:configuration){ @config }
    @solr_home = File.join(@config.solr_home)
  end

  it "sets the correct Solr home" do
    expect(@server.solr_home).to eq(@solr_home)
  end

  it "sets the correct Solr PID path" do
    expect(@server.pid_path).to eq(File.join(@server.pid_dir, 'sunspot-solr-test.pid'))
  end

  it "sets the correct port" do
    expect(@server.port).to eq(8983)
  end

  it "sets the log level using configuration" do
    allow(@config).to receive(:log_level){ 'WARNING' }
    expect(@server.log_level).to eq("WARNING")
  end

  it "sets the correct log file" do
    expect(@server.log_file).to eq(File.join(Rails.root, 'log', 'sunspot-solr-test.log'))
  end
end
