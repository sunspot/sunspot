require 'thread'
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'Sunspot::Rails session' do
  it 'is a different object for each thread' do
    # Queue is just a convenient thread-safe container
    sessions_queue = Queue.new

    # Create some threads which dump their session into the queue
    Array.new(2) {
      Thread.new { sessions_queue << Sunspot.session.session }
    }.each { |thread| thread.join }

    # Collect the items from the queue
    sessions = []
    until sessions_queue.empty?
      sessions << sessions_queue.pop
    end

    # There should be no items in the queue with the same object_id
    object_ids = sessions.map(&:object_id)
    object_ids.uniq.should == object_ids
  end

  it 'should create a separate master/slave session if configured' do
  end

  it 'should not create a separate master/slave session if no master configured' do
  end

  context 'disabled' do
    before do
      Sunspot::Rails.reset
      ::Rails.stub!(:env).and_return("config_disabled_test")
    end

    after do
      Sunspot::Rails.reset
    end

    it 'sets the session proxy as a stub' do
      Sunspot::Rails.build_session.should be_a_kind_of(Sunspot::Rails::StubSessionProxy)
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
