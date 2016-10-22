require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::SolrInstrumentation do
  it "should include instance method send_and_receive" do
    expect(Sunspot::SolrRailsInstrumentation.instance_methods.include?(:send_and_receive)).to eq true
  end
end