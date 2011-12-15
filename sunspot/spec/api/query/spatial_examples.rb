require 'bigdecimal'

shared_examples_for "spatial query" do
  it 'filters by radius' do
    search do
      with(:coordinates_new).in_radius(23, -46, 100)
    end

    connection.should have_last_search_including(:fq, "{!geofilt sfield=coordinates_new_ll pt=23,-46 d=100}")
  end
end
