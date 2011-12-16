require 'bigdecimal'

shared_examples_for "spatial query" do
  it 'filters by radius' do
    search do
      with(:coordinates_new).in_radius(23, -46, 100)
    end

    connection.should have_last_search_including(:fq, "{!geofilt sfield=coordinates_new_ll pt=23,-46 d=100}")
  end

  it 'filters by radius via bbox (inexact)' do
    search do
      with(:coordinates_new).in_radius(23, -46, 100, :bbox => true)
    end

    connection.should have_last_search_including(:fq, "{!bbox sfield=coordinates_new_ll pt=23,-46 d=100}")
  end

  it 'filters by bounding box' do
    search do
      with(:coordinates_new).in_bounding_box([45, -94], [46, -93])
    end

    connection.should have_last_search_including(:fq, "coordinates_new_ll:[45,-94 TO 46,-93]")
  end
end
