require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Rails::Server do
  before(:each) do
    @sunspot_configuration = Sunspot::Rails::Configuration.new
  end

  describe "rake task commands" do
    it "should generate and execute the start command" do
      Sunspot::Rails::Server.should_receive(:start_command).and_return('sunspot-start')
      Sunspot::Rails::Server.should_respond_to_and_receive(:bootstrap_neccessary?).and_return(false)
      Kernel.should_receive(:system).with('sunspot-start').and_return(true)
      Sunspot::Rails::Server.start.should == true
    end

    it "should generate and execute the stop command" do
      Sunspot::Rails::Server.should_receive(:stop_command).and_return('sunspot-stop')
      Sunspot::Rails::Server.should_not_receive(:bootstrap_neccessary?)
      Kernel.should_receive(:system).with('sunspot-stop').and_return(true)
      Sunspot::Rails::Server.stop.should == true
    end

    it "should generate and execute the run command" do
      Sunspot::Rails::Server.should_receive(:run_command).and_return('sunspot-run')
      Sunspot::Rails::Server.should_respond_to_and_receive(:bootstrap_neccessary?).and_return(false)
      Kernel.should_receive(:system).with('sunspot-run').and_return(true)
      Sunspot::Rails::Server.run.should == true
    end
  end

  describe "delegate methods" do
    before(:each) do
      Sunspot::Rails::Server.should_receive(:configuration).and_return(@sunspot_configuration)
    end

    it "should delegate the port command to the configuration" do
      @sunspot_configuration.should_respond_to_and_receive(:port).and_return(1234)
      Sunspot::Rails::Server.port.should == 1234
    end
  end

  describe "protected methods" do
    it "should generate the start command" do
      Sunspot::Rails::Server.should_receive(:port).and_return('1')
      Sunspot::Rails::Server.should_receive(:solr_home).and_return('home')
      Sunspot::Rails::Server.should_receive(:data_path).and_return('data')
      Sunspot::Rails::Server.send(:start_command).should == [ 'sunspot-solr', 'start', '--', '-p', '1', '-d', 'data', '-s', 'home' ]
    end
  
    it "should generate the stop command" do
      Sunspot::Rails::Server.send(:stop_command).should == [ 'sunspot-solr', 'stop' ]
    end
  
    it "should generate the run command" do
      Sunspot::Rails::Server.send(:run_command).should == [ 'sunspot-solr', 'run' ]
    end
  
    it "should generate the path for solr_home"

    it "should generate the path for configs"
  
    it "should generate the path for the index data"

    it "should generate the path for pids"

  end
end