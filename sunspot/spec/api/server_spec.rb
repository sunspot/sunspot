require File.join(File.dirname(__FILE__), 'spec_helper')
require 'tempfile'

describe Sunspot::Server do
  SUNSPOT_START_JAR = File.expand_path(
    File.join(File.dirname(__FILE__), '..', '..', 'solr', 'solr', 'start.jar')
  )

  before :each do
    @server = Sunspot::Server.new
  end

  after :each do
    if File.exist?('./sunspot-solr.pid')
      FileUtils.rm('./sunspot-solr.pid')
    end
  end

  it 'starts server with basic options' do
    @server.stub!(:fork).and_yield
    @server.should_receive(:exec).with("java -jar #{SUNSPOT_START_JAR}")
    @server.start
  end

  it 'writes PID file to default location' do
    @server.stub!(:fork).and_yield.and_return(123)
    @server.stub!(:exec)
    @server.start
    IO.read('./sunspot-solr.pid').to_i.should == 123
  end

  it 'writes PID file to specified directory' do
    @server.pid_dir = 'spec/tmp/pids'
    @server.stub!(:fork).and_yield.and_return(123)
    @server.stub!(:exec)
    @server.start
    IO.read('./spec/tmp/pids/sunspot-solr.pid').to_i.should == 123
    FileUtils.rm_r('./spec/tmp')
  end

  it 'writes PID to specified file' do
    @server.pid_file = 'spec/tmp/pids/solr-development.pid'
    @server.stub!(:fork).and_yield.and_return(123)
    @server.stub!(:exec)
    @server.start
    IO.read('./spec/tmp/pids/solr-development.pid').to_i.should == 123
    FileUtils.rm_r('./spec/tmp')
  end

  it 'runs server in current process' do
    @server.should_not_receive(:fork)
    @server.should_receive(:exec).with("java -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  it 'runs Java with min memory' do
    @server.min_memory = 1024
    @server.should_receive(:exec).with("java -Xms1024 -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  it 'runs Java with max memory' do
    @server.max_memory = 2048
    @server.should_receive(:exec).with("java -Xmx2048 -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  it 'runs Jetty with specified port' do
    @server.port = 8981
    @server.should_receive(:exec).with("java -Djetty.port=8981 -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  it 'runs Solr with specified data dir' do
    @server.solr_data_dir = '/var/solr/data'
    @server.should_receive(:exec).with("java -Dsolr.data.dir=/var/solr/data -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  it 'runs Solr with specified Solr home' do
    @server.solr_home = '/var/solr'
    @server.should_receive(:exec).with("java -Dsolr.solr.home=/var/solr -jar #{SUNSPOT_START_JAR}")
    @server.run
  end

  describe 'with logging' do
    before :each do
      @server.log_level = 'debug'
      @server.log_file = 'log/sunspot-development.log'
      Tempfile.should_receive(:new).with('logging.properties').and_return(@tempfile = StringIO.new)
      @tempfile.should_receive(:flush)
      @tempfile.should_receive(:close)
      @tempfile.stub(:path).and_return('/tmp/logging.properties.12345')
      @server.stub(:exec)
    end

    it 'runs Solr with logging properties file' do
      @server.should_receive(:exec).with("java -Djava.util.logging.config.file=/tmp/logging.properties.12345 -jar #{SUNSPOT_START_JAR}")
      @server.run
    end

    it 'sets logging level' do
      @server.run
      @tempfile.string.should =~ /^\.level *= *DEBUG$/
    end

    it 'sets handler' do
      @server.run
      @tempfile.string.should =~ /^handlers *= *java.util.logging.FileHandler$/
    end

    it 'sets formatter' do
      @server.run
      @tempfile.string.should =~ /^java\.util\.logging\.FileHandler\.formatter *= *java\.util\.logging\.SimpleFormatter$/
    end

    it 'sets log file' do
      @server.run
      @tempfile.string.should =~ /^java\.util\.logging\.FileHandler\.pattern *= *log\/sunspot-development\.log$/
    end
  end
end
