require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'Sunspot::Rails session' do
  it 'should be a different object for each thread' do
  end

  it 'should create a separate master/slave session if configured' do
  end

  it 'should not create a separate master/slave session if no master configured' do
  end

  it 'should do nothing to the session if disable_solr: false (default) ' do
    @config = Sunspot::Rails::Configuration.new
    @config.disable_solr?.should == false
    Sunspot.session.class.should == Sunspot::SessionProxy::ThreadLocalSessionProxy
  end

  describe 'disable_solr' do
    before(:each) do
      ::Rails.stub!(:env => 'disabled')
      @config = Sunspot::Rails::Configuration.new
    end

    after(:each) do
      ::Rails.stub!(:env => 'config_test')
      if Sunspot.session.class == Sunspot::Rails::StubSessionProxy
        Sunspot.session = Sunspot.session.original_session
      end
    end

    it 'should stub the session if disable_solr: true' do
      @config.disable_solr?.should == true
      Sunspot.session.class.should == Sunspot::Rails::StubSessionProxy
      Sunspot.session = Sunspot.session.original_session
    end
  end

  private

  def with_configuration(options)
    original_configuration = Sunspot::Rails.configuration
    Sunspot::Rails.reset
    Sunspot::Rails.configuration = Sunspot::Rails::Configuration.new
    Sunspot::Rails.configuration.user_configuration = options
    yield
    Sunspot::Rails.reset
    Sunspot::Rails.configuration = original_configuration
  end
end
