require File.join(File.dirname(__FILE__), 'spec_helper')

shared_examples_for "query with adjustable params" do
  before :each do
    search do
      adjust_solr_params do |params|
        params[:rows] = 40
        params[:qt] = 'complicated'
      end
    end
  end

  it "modifies existing param" do
    connection.should have_last_search_with(:rows  => 40)
  end

  it "adds new param" do
    connection.should have_last_search_with(:qt => 'complicated')
  end
end
