require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Sunspot::Rails session' do
  it 'should be a different object for each thread' do
    session1 = nil
    session2 = nil
    Thread.new { session1 = Sunspot::Rails.session }.join
    Thread.new { session2 = Sunspot::Rails.session }.join
    session1.should_not eql(session2)
  end

  it 'should create a separate master/slave session if configured' do
    with_configuration(
      'master_solr' => { 'hostname' => 'mastersolr.myapp.com' },
      'solr' => { 'hostname' => 'slavesolr.myapp.com' }
    ) do
      Sunspot::Rails.session.should_not eql(Sunspot::Rails.master_session)
    end
  end

  it 'should not create a separate master/slave session if no master configured' do
    with_configuration(
      'solr' => { 'hostname' => 'solr.myapp.com' }
    ) do
      Sunspot::Rails.session.should eql(Sunspot::Rails.session)
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
