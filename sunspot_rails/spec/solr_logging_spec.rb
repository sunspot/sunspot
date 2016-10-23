require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::SolrLogging do

  it "should respond_to execute_with_rails_logging" do
    expect(Sunspot::Rails::SolrLogging.instance_methods.include?(:execute)).to eq true
  end
end