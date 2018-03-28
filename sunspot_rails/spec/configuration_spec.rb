require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Configuration, "default values without a sunspot.yml" do
  before(:each) do
    allow(File).to receive(:exist?).and_return(false) # simulate sunspot.yml not existing
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'hostname' property when not set" do
    expect(@config.hostname).to eq('localhost')
  end

  it "should handle the 'path' property when not set" do
    expect(@config.path).to eq('/solr/default')
  end

  it "should set the scheme to http" do
    expect(@config.scheme).to eq("http")
  end

  it "should not have userinfo" do
    expect(@config.userinfo).to be_nil
  end

  it "should not set a proxy" do
    expect(@config.proxy).to be_nil
  end

  describe "port" do
    it "should default to port 8981 in test" do
      allow(::Rails).to receive(:env).and_return('test')
      @config = Sunspot::Rails::Configuration.new
      expect(@config.port).to eq(8981)
    end
    it "should default to port 8982 in development" do
      allow(::Rails).to receive(:env).and_return('development')
      @config = Sunspot::Rails::Configuration.new
      expect(@config.port).to eq(8982)
    end
    it "should default to 8983 in production" do
      allow(::Rails).to receive(:env).and_return('production')
      @config = Sunspot::Rails::Configuration.new
      expect(@config.port).to eq(8983)
    end
    it "should generally default to 8983" do
      allow(::Rails).to receive(:env).and_return('staging')
      @config = Sunspot::Rails::Configuration.new
      expect(@config.port).to eq(8983)
    end
  end

  it "should set the read timeout to nil when not set" do
    expect(@config.read_timeout).to be_nil
  end

  it "should set the open timeout to nil when not set" do
    expect(@config.open_timeout).to be_nil
  end

  it "should set the update_format to nil when not set" do
    expect(@config.update_format).to be_nil
  end

  it "should set 'log_level' property using Rails log level when not set" do
    allow(::Rails.logger).to receive(:level){ 3 }
    expect(@config.log_level).to eq('SEVERE')
  end

  it "should handle the 'log_file' property" do
    expect(@config.log_file).to match(/log\/solr_test.log/)
  end

  it "should handle the 'solr_home' property when not set" do
    expect(Rails).to receive(:root).at_least(1).and_return('/some/path')
    expect(@config.solr_home).to eq('/some/path/solr')
  end

  it "should handle the 'pid_dir' property when not set" do
    expect(Rails).to receive(:root).at_least(1).and_return('/some/path')
    expect(@config.pid_dir).to eq('/some/path/solr/pids/test')
  end

  it "should handle the 'auto_commit_after_request' propery when not set" do
    expect(@config.auto_commit_after_request?).to eq(true)
  end

  it "should handle the 'auto_commit_after_delete_request' propery when not set" do
    expect(@config.auto_commit_after_delete_request?).to eq(false)
  end

  it "should handle the 'bind_address' property when not set" do
    expect(@config.bind_address).to be_nil
  end

  it "should handle the 'disabled' property when not set" do
    expect(@config.disabled?).to be_falsey
  end

  it "should handle the 'auto_index_callback' property when not set" do
    expect(@config.auto_index_callback).to eq("after_save")
  end

  it "should handle the 'auto_remove_callback' property when not set" do
    expect(@config.auto_remove_callback).to eq("after_destroy")
  end
end

describe Sunspot::Rails::Configuration, "user provided sunspot.yml" do
  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'scheme' property when set" do
    expect(@config.scheme).to eq("http")
  end

  it "should handle the 'user' and 'pass' properties when set" do
    expect(@config.userinfo).to eq("user:pass")
  end

  it "should handle the 'hostname' property when set" do
    expect(@config.hostname).to eq('some.host')
  end

  it "should handle the 'port' property when set" do
    expect(@config.port).to eq(1234)
  end

  it "should handle the 'path' property when set" do
    expect(@config.path).to eq('/solr/idx')
  end

  it "should handle the 'log_level' propery when set" do
    expect(@config.log_level).to eq('WARNING')
  end

  it "should handle the 'solr_home' propery when set" do
    expect(@config.solr_home).to eq('/my_superior_path')
  end

  it "should handle the 'pid_dir' property when set" do
    expect(@config.pid_dir).to eq('/my_superior_path/pids')
  end

  it "should handle the 'solr_home' property when set" do
    expect(@config.solr_home).to eq('/my_superior_path')
  end

  it "should handle the 'auto_commit_after_request' propery when set" do
    expect(@config.auto_commit_after_request?).to eq(false)
  end

  it "should handle the 'auto_commit_after_delete_request' propery when set" do
    expect(@config.auto_commit_after_delete_request?).to eq(true)
  end

  it "should handle the 'bind_address' property when set" do
    expect(@config.bind_address).to eq("127.0.0.1")
  end

  it "should handle the 'read_timeout' property when set" do
    expect(@config.read_timeout).to eq(2)
  end

  it "should handle the 'open_timeout' property when set" do
    expect(@config.open_timeout).to eq(0.5)
  end

  it "should handle the 'update_format' property when set" do
    expect(@config.update_format).to eq('json')
  end

  it "should handle the 'proxy' property when set" do
    expect(@config.proxy).to eq('http://proxy.com:12345')
  end
end

describe Sunspot::Rails::Configuration, "with auto_index_callback and auto_remove_callback set" do
  before do
    allow(::Rails).to receive(:env).and_return('config_commit_test')
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'auto_index_callback' property when set" do
    expect(@config.auto_index_callback).to eq("after_commit")
  end

  it "should handle the 'auto_remove_callback' property when set" do
    expect(@config.auto_remove_callback).to eq("after_commit")
  end
end

describe Sunspot::Rails::Configuration, "with disabled: true in sunspot.yml" do
  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_disabled_test')
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'disabled' property when set" do
    expect(@config.disabled?).to be_truthy
  end
end

describe Sunspot::Rails::Configuration, "with ENV['SOLR_URL'] overriding sunspot.yml" do
  before(:all) do
    ENV['SOLR_URL'] = 'http://environment.host:5432/solr/env'
  end

  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('SOLR_URL')
  end

  it "should handle the 'hostname' property when set" do
    expect(@config.hostname).to eq('environment.host')
  end

  it "should handle the 'port' property when set" do
    expect(@config.port).to eq(5432)
  end

  it "should handle the 'path' property when set" do
    expect(@config.path).to eq('/solr/env')
  end
end

describe Sunspot::Rails::Configuration, "with ENV['WEBSOLR_URL'] overriding sunspot.yml" do
  before(:all) do
    ENV['WEBSOLR_URL'] = 'http://index.websolr.test/solr/a1b2c3d4e5f'
  end

  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('WEBSOLR_URL')
  end

  it "should handle the 'hostname' property when set" do
    expect(@config.hostname).to eq('index.websolr.test')
  end

  it "should handle the 'port' property when set" do
    expect(@config.port).to eq(80)
  end

  it "should handle the 'path' property when set" do
    expect(@config.path).to eq('/solr/a1b2c3d4e5f')
  end
end

describe Sunspot::Rails::Configuration, "with ENV['WEBSOLR_URL'] using https" do
  before(:all) do
    ENV['WEBSOLR_URL'] = 'https://index.websolr.test/solr/a1b2c3d4e5f'
  end

  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('WEBSOLR_URL')
  end

  it "should set the scheme to https" do
    expect(@config.scheme).to eq("https")
  end

  it "should handle the 'hostname' property when set" do
    expect(@config.hostname).to eq('index.websolr.test')
  end

  it "should handle the 'port' property when set" do
    expect(@config.port).to eq(443)
  end

  it "should handle the 'path' property when set" do
    expect(@config.path).to eq('/solr/a1b2c3d4e5f')
  end
end

describe Sunspot::Rails::Configuration, "with ENV['WEBSOLR_URL'] including userinfo" do
  before(:all) do
    ENV['WEBSOLR_URL'] = 'https://user:pass@index.websolr.test/solr/a1b2c3d4e5f'
  end

  before(:each) do
    allow(::Rails).to receive(:env).and_return('config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('WEBSOLR_URL')
  end

  it "should include username and passowrd" do
    expect(@config.userinfo).to eq("user:pass")
  end

  it "should set the scheme to https" do
    expect(@config.scheme).to eq("https")
  end

  it "should handle the 'hostname' property when set" do
    expect(@config.hostname).to eq('index.websolr.test')
  end

  it "should handle the 'port' property when set" do
    expect(@config.port).to eq(443)
  end

  it "should handle the 'path' property when set" do
    expect(@config.path).to eq('/solr/a1b2c3d4e5f')
  end
end
