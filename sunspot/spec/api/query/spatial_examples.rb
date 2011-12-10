require 'bigdecimal'

shared_examples_for "spatial query" do
  it 'searches by spatial' do
    search do
      spatial(:coordinates, 23, -46, :radius => 100)
    end

    connection.should have_last_search_including(:sort, "geodist() asc")
    connection.should have_last_search_including(:fq, "{!geofilt}")
    connection.should have_last_search_including(:pt, "23,-46")
  end
end
