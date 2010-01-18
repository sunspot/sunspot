require File.join(File.dirname(__FILE__), '..', 'spec_helper')

shared_examples_for 'session proxy' do
  Sunspot::Session.public_instance_methods(false).each do |method|
    it "should respond to #{method.inspect}" do
      @proxy.should respond_to(method)
    end
  end
end
