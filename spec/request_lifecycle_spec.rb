require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'request lifecycle', :type => :controller do
  before(:each) do
    Sunspot::Rails.configuration = @configuration = Sunspot::Rails::Configuration.new
  end

  after(:each) do
    Sunspot::Rails.configuration = nil
  end
  controller_name :posts

  it 'should automatically commit after each action if specified' do
    @configuration.user_configuration = { 'auto_commit_after_request' => true }
    Sunspot.should_receive(:commit_if_dirty)
    post :create, :post => { :title => 'Test 1' }
  end
  
  it 'should not commit, if configuration is set to false' do
    @configuration.user_configuration = { 'auto_commit_after_request' => false }
    Sunspot.should_not_receive(:commit_if_dirty)
    post :create, :post => { :title => 'Test 1' }
  end

  it 'should commit if configuration is not specified' do
    @configuration.user_configuration = {}
    Sunspot.should_receive(:commit_if_dirty)
    post :create, :post => { :title => 'Test 1' }
  end
end
