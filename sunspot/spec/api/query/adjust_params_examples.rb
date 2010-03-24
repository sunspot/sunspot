require File.join(File.dirname(__FILE__), 'spec_helper')

shared_examples_for "query with adjustable params" do
  it "should send query to solr with adjusted parameters (keyword example)" do
    search do
      keywords 'keyword search'
      adjust_solr_params do |params|
        params[:q]    = 'new search'
        params[:some] = 'param'
      end
    end
    connection.should have_last_search_with(:q    => 'new search')
    connection.should have_last_search_with(:some => 'param')
  end
  
  it "should work, even without another dsl command" do
    search do
      adjust_solr_params do |params|
        params[:q]    = 'napoleon dynamite'
        params[:qt]   = 'complicated'
      end
    end
    connection.should have_last_search_with(:q  => 'napoleon dynamite')
    connection.should have_last_search_with(:qt => 'complicated')
  end
  
  it "should be able to extend parameters" do
    search do
      keywords 'keyword search'
      adjust_solr_params do |params|
        params[:q]    += ' AND something_s:more'
      end
    end
    connection.should have_last_search_with(:q => 'keyword search AND something_s:more')
  end
  
end
