require File.join(File.dirname(__FILE__), 'spec_helper')

shared_examples_for "spatial query" do
  it 'sends lat and lng, and distance when geo search is performed' do
    search do
      near [40.7, -73.5], :distance => 5
    end
    connection.should have_last_search_with(:spatial => "{!radius=5}40.7,-73.5")
  end

  it 'sets lat, lng, and sort flag when sorted geo search is performed' do
    search do
      near [40.7, -73.5], :sort => true
    end
    connection.should have_last_search_with(:spatial => "{!sort=true}40.7,-73.5")
  end

  it 'sets radius and sort when both are specified' do
    search do
      near [40.7, -73.5], :distance => 5, :sort => true
    end
    connection.should have_last_search_with(:spatial => "{!radius=5 sort=true}40.7,-73.5")
  end

  [
    [:lat, :lng],
    [:lat, :lon],
    [:lat, :long],
    [:latitude, :longitude]
  ].each do |lat_attr, lng_attr|
    it "sets coordinates using #{lat_attr.inspect}, #{lng_attr.inspect}" do
      search do
        near OpenStruct.new(lat_attr => 40.7, lng_attr => -73.5), :distance => 5
      end
      connection.should have_last_search_with(:spatial => "{!radius=5}40.7,-73.5")
    end
  end
end
