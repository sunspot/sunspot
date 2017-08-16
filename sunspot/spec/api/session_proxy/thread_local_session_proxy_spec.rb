require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'weakref'

describe Sunspot::SessionProxy::ThreadLocalSessionProxy do
  context 'when not passing a config' do
    before :each do
      @proxy = Sunspot::SessionProxy::ThreadLocalSessionProxy.new
    end

    it_should_behave_like 'session proxy'
  end

  context 'when passing a config' do
    before :each do
      @config = Sunspot::Configuration.build
      @proxy = Sunspot::SessionProxy::ThreadLocalSessionProxy.new(@config)
    end

    it 'should have the same session for the same thread' do
      expect(@proxy.session).to eql(@proxy.session)
    end

    it 'should not have the same session for different threads' do
      session1 = @proxy.session
      session2 = nil
      Thread.new do
        session2 = @proxy.session
      end.join
      expect(session1).not_to eql(session2)
    end

    it 'should not have the same session for the same thread in different proxy instances' do
      proxy2 = Sunspot::SessionProxy::ThreadLocalSessionProxy.new(@config)
      expect(@proxy.session).not_to eql(proxy2.session)
    end

    (Sunspot::Session.public_instance_methods(false) - ['config', :config]).each do |method|
      it "should delegate #{method.inspect} to its session" do
        args = Array.new(Sunspot::Session.instance_method(method).arity.abs) do
          double('arg')
        end
        if args.empty?
          expect(@proxy.session).to receive(method).with(no_args)
        else
          expect(@proxy.session).to receive(method).with(*args)
        end
        @proxy.send(method, *args)
      end
    end

    it_should_behave_like 'session proxy'
  end
end
