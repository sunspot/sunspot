require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'request lifecycle', :type => :controller do
  controller_name :posts

  it 'should automatically commit after each action' do
    post :create, :post => { :title => 'Test 1' }
    PostWithAuto.search { with :title, 'Test 1' }.results.should_not be_empty
  end
end
