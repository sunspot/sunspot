require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::SolrInstrumentation do

  it "should respond_to execute_with_rails_logging" do
    expect(Sunspot::Rails::SolrInstrumentation.instance_methods.include?(:send_and_receive_without_as_instrumentation)).to eq !Module.respond_to?(:prepend)
  end
end