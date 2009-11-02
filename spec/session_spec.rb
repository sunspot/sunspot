require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Sunspot::Rails session' do
  it 'should be a different object for each thread' do
  end

  it 'should create a separate master/slave session if configured' do
  end

  it 'should not create a separate master/slave session if no master configured' do
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
