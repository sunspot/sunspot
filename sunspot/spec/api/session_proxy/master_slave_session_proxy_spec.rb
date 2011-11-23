require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::MasterSlaveSessionProxy do
  before :each do
    @master_session, @slave_session = Sunspot::Session.new, Sunspot::Session.new
    @proxy = Sunspot::SessionProxy::MasterSlaveSessionProxy.new(@master_session, @slave_session)
  end

  {
    :master_session => Sunspot::Session.public_instance_methods(false) - [:search, 'search', :new_search, 'new_search', :more_like_this, 'more_like_this', :new_more_like_this, 'new_more_like_this', :config, 'config'],
    :slave_session => [:search, :new_search, :more_like_this, :new_more_like_this]
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
