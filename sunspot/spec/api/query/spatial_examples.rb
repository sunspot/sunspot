require 'bigdecimal'

shared_examples_for "spatial query" do
  it 'searches by spatial' do
    search do
      spatial(:coordinates, BigDecimal.new('-23.57'), BigDecimal.new('-46.53'), 100)      
    end    
    connection.should have_last_search_including(:sort, "geodist() asc") 	
    connection.should have_last_search_including(:fq, "{!geofilt}")   
    connection.should have_last_search_including(:pt, "#{BigDecimal.new('-23.57')},#{BigDecimal.new('-46.53')}")       
  end
end