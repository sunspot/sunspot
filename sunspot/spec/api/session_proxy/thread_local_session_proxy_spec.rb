require File.join(File.dirname(__FILE__), 'spec_helper')
require 'weakref'

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

  it 'should not have the same session for the same thread in different proxy instances' do
    proxy2 = Sunspot::SessionProxy::ThreadLocalSessionProxy.new(@config)
    @proxy.session.should_not eql(proxy2.session)
  end

  it 'should garbage collect session instance when proxy dereferenced' do
    ref = WeakRef.new(@proxy.session)
    @proxy = nil
    GC.start
    # need to do this a second time since the reference to the session is
    # destroyed in the finalizer during the first GC run, and thus isn't picked
    # up by that run.
    GC.start 
    lambda { ref.inspect }.should raise_error(WeakRef::RefError)
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
