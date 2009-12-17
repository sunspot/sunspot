require File.join(File.dirname(__FILE__), 'spec_helper')

shared_examples_for 'session proxy' do
  Sunspot::Session.public_instance_methods(false).each do |method|
    it "should respond to #{method.inspect}" do
      @proxy.should respond_to(method)
    end
  end
end

describe Sunspot::SessionProxy::ThreadLocalSessionProxy do
  before :each do
    @config = Sunspot::Configuration.build
    @proxy = Sunspot::SessionProxy::ThreadLocalSessionProxy.new(@config)
  end

  it 'should have the same session for the same thread' do
    @proxy.session.should eql(@proxy.session)
  end

  it 'should not have the same session for different threads' do
    session1 = @proxy.session
    session2 = nil
    Thread.new do
      session2 = @proxy.session
    end.join
    session1.should_not eql(session2)
  end

  (Sunspot::Session.public_instance_methods(false) - ['config', :config]).each do |method|
    it "should delegate #{method.inspect} to its session" do
      args = Array.new(Sunspot::Session.instance_method(method).arity.abs) do
        stub('arg')
      end
      @proxy.session.should_receive(method).with(*args)
      @proxy.send(method, *args)
    end
  end

  it_should_behave_like 'session proxy'
end

describe Sunspot::SessionProxy::MasterSlaveSessionProxy do
  before :each do
    @master_session, @slave_session = Sunspot::Session.new, Sunspot::Session.new
    @proxy = Sunspot::SessionProxy::MasterSlaveSessionProxy.new(@master_session, @slave_session)
  end

  {
    :master_session => Sunspot::Session.public_instance_methods(false) - [:search, 'search', :new_search, 'new_search', :config, 'config'],
    :slave_session => [:search, :new_search]
  }.each_pair do |delegate, methods|
    methods.each do |method|
      it "should delegate #{method} to #{delegate}" do
        args = Array.new(Sunspot::Session.instance_method(method).arity.abs) do
          stub('arg')
        end
        instance_variable_get(:"@#{delegate}").should_receive(method).with(*args)
        @proxy.send(method, *args)
      end
    end
  end

  it 'should return master session config by default' do
    @proxy.config.should eql(@master_session.config)
  end

  it 'should return master session config when specified' do
    @proxy.config(:master).should eql(@master_session.config)
  end

  it 'should return slave session config when specified' do
    @proxy.config(:slave).should eql(@slave_session.config)
  end

  it 'should raise ArgumentError when bogus config specified' do
    lambda { @proxy.config(:bogus) }.should raise_error
  end

  it_should_behave_like 'session proxy'
end
