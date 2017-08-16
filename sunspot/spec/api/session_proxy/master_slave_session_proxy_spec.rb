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
          double('arg')
        end
        if args.empty?
          expect(instance_variable_get(:"@#{delegate}")).to receive(method).with(no_args)
        else
          expect(instance_variable_get(:"@#{delegate}")).to receive(method).with(*args)
        end
        @proxy.send(method, *args)
      end
    end
  end

  it 'should return master session config by default' do
    expect(@proxy.config).to eql(@master_session.config)
  end

  it 'should return master session config when specified' do
    expect(@proxy.config(:master)).to eql(@master_session.config)
  end

  it 'should return slave session config when specified' do
    expect(@proxy.config(:slave)).to eql(@slave_session.config)
  end

  it 'should raise ArgumentError when bogus config specified' do
    expect { @proxy.config(:bogus) }.to raise_error
  end

  it_should_behave_like 'session proxy'
end
