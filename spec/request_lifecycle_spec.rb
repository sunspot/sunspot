require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'request lifecycle', :type => :controller do
  before(:each) do
    @sunspot_configuration = mock('configuration')
    Sunspot::Rails.should_receive(:configuration).and_return( @sunspot_configuration )
  end
  controller_name :posts

  it 'should automatically commit after each action' do
    @sunspot_configuration.should_receive(:auto_commit_after_request?).and_return( true )
    post :create, :post => { :title => 'Test 1' }
    PostWithAuto.search { with :title, 'Test 1' }.results.should_not be_empty
  end
  
  it 'should not commit, if configuration is set to false' do
    @sunspot_configuration.should_receive(:auto_commit_after_request?).and_return( false )
    Sunspot.should_not_receive(:commit_if_dirty)
    post :create, :post => { :title => 'Test 1' }
    PostWithAuto.search { with :title, 'Test 1' }.results.should be_empty
  end
end
