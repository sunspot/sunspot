require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'tempfile'

describe Sunspot::Solr::Server do
  SUNSPOT_START_JAR = File.expand_path(
    File.join(File.dirname(__FILE__), '..', '..', 'solr', 'start.jar')
  )

  before :each do
    @server = Sunspot::Solr::Server.new
  end

  it 'runs server in current process' do
    @server.should_not_receive(:fork)
    @server.should_receive(:exec).with(/java .*-jar start.jar/)
    @server.run
  end

  it 'runs Java with min memory' do
    @server.min_memory = 1024
    @server.should_receive(:exec).with(/-Xms1024/)
    @server.run
  end

  it 'runs Java with max memory' do
    @server.max_memory = 2048
    @server.should_receive(:exec).with(/-Xmx2048/)
    @server.run
  end

  it 'runs Jetty with specified port' do
    @server.port = 8981
    @server.should_receive(:exec).with(/-Djetty\.port=8981/)
    @server.run
  end

  it 'runs Solr with specified data dir' do
    @server.solr_data_dir = '/tmp/var/solr/data'
    @server.should_receive(:exec).with(%r(-Dsolr\.data\.dir=/tmp/var/solr/data))
    @server.run
  end

  it 'runs Solr with specified Solr home' do
    @server.solr_home = '/tmp/var/solr'
    @server.should_receive(:exec).with(%r(-Dsolr\.solr\.home=/tmp/var/solr))
    @server.run
  end

  it 'runs Solr with specified Solr jar' do
    @server.solr_jar = SUNSPOT_START_JAR
    FileUtils.should_receive(:cd).with(File.dirname(SUNSPOT_START_JAR))
    @server.run
  end

  it 'raises an error if java is missing' do
    Sunspot::Solr::Java.stub(:installed? => false)
    expect {
     Sunspot::Solr::Server.new
    }.to raise_error(Sunspot::Solr::Server::JavaMissing)
  end

  describe 'with logging' do
    before :each do
      @server.log_level = 'info'
      @server.log_file = 'log/sunspot-development.log'
      Tempfile.should_receive(:new).with('logging.properties').and_return(@tempfile = StringIO.new)
      @tempfile.should_receive(:flush)
      @tempfile.should_receive(:close)
      @tempfile.stub!(:path).and_return('/tmp/logging.properties.12345')
      @server.stub!(:exec)
    end

    it 'runs Solr with logging properties file' do
      @server.should_receive(:exec).with(%r(-Djava\.util\.logging\.config\.file=/tmp/logging\.properties\.12345))
      @server.run
    end

    it 'sets logging level' do
      @server.run
      @tempfile.string.should =~ /^java\.util\.logging\.FileHandler\.level *= *INFO$/
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
