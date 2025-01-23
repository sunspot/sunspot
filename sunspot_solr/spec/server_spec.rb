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
    expect(@server).not_to receive(:fork)
    expect(@server).to receive(:exec).with(/java .*-jar start.jar/)
    @server.run
  end

  it 'runs Java with min memory' do
    @server.min_memory = 1024
    expect(@server).to receive(:exec).with(/-Xms1024/)
    @server.run
  end

  it 'runs Java with max memory' do
    @server.max_memory = 2048
    expect(@server).to receive(:exec).with(/-Xmx2048/)
    @server.run
  end

  it 'runs Jetty with specified port' do
    @server.port = 8981
    expect(@server).to receive(:exec).with(/-Djetty\.port=8981/)
    @server.run
  end

  it 'runs Solr with specified data dir' do
    @server.solr_data_dir = '/tmp/var/solr/data'
    expect(@server).to receive(:exec).with(%r(-Dsolr\.data\.dir=/tmp/var/solr/data))
    @server.run
  end

  it 'runs Solr with specified Solr home' do
    @server.solr_home = '/tmp/var/solr'
    expect(@server).to receive(:exec).with(%r(-Dsolr\.solr\.home=/tmp/var/solr))
    @server.run
  end

  it 'runs Solr with specified Solr jar' do
    @server.solr_jar = SUNSPOT_START_JAR
    expect(FileUtils).to receive(:cd).with(File.dirname(SUNSPOT_START_JAR))
    @server.run
  end

  it 'raises an error if java is missing' do
    allow(Sunspot::Solr::Java).to receive(:installed?).and_return(false)
    expect {
      Sunspot::Solr::Server.new
    }.to raise_error(Sunspot::Solr::Server::JavaMissing)
  end
  
  describe 'with logging' do
    before :each do
      @server.log_level = 'info'
      @server.log_file = 'log/sunspot-development.log'
      expect(Tempfile).to receive(:new).with('logging.properties').and_return(@tempfile = StringIO.new)
      expect(@tempfile).to receive(:flush)
      expect(@tempfile).to receive(:close)
      
      # Replace `stub` with `allow`
      allow(@tempfile).to receive(:path).and_return('/tmp/logging.properties.12345')
      allow(@server).to receive(:exec)
    end
  
    it 'runs Solr with logging properties file' do
      expect(@server).to receive(:exec).with(%r(-Djava\.util\.logging\.config\.file=/tmp/logging\.properties\.12345))
      @server.run
    end

    it 'sets logging level' do
      @server.run
      expect(@tempfile.string).to match(/^java\.util\.logging\.FileHandler\.level *= *INFO$/)
    end

    it 'sets handler' do
      @server.run
      expect(@tempfile.string).to match(/^handlers *= *java.util.logging.FileHandler$/)
    end

    it 'sets formatter' do
      @server.run
      expect(@tempfile.string).to match(/^java\.util\.logging\.FileHandler\.formatter *= *java\.util\.logging\.SimpleFormatter$/)
    end

    it 'sets log file' do
      @server.run
      expect(@tempfile.string).to match(/^java\.util\.logging\.FileHandler\.pattern *= *log\/sunspot-development\.log$/)
    end
  end
end
