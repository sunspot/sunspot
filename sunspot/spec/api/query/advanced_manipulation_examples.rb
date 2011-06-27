require File.expand_path('spec_helper', File.dirname(__FILE__))

shared_examples_for "query with advanced manipulation" do
  describe 'adjust_solr_params' do
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

  describe 'request_handler' do
    before :each do
      connection.expected_handler = :myRequestHandler
      search do
        request_handler :myRequestHandler
      end
    end

    it 'should use specified request handler' do
      connection.should have_last_search_with({})
    end
  end
end
