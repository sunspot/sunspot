require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'local query' do
  it 'sets query type to geo when geo search performed' do
    session.search Post do
      near [40.7, -73.5], 5
    end
    connection.should have_last_search_with(:qt => 'geo')
  end

  it 'sets lat and lng when geo search is performed' do
    session.search Post do
      near [40.7, -73.5], 5
    end
    connection.should have_last_search_with(:lat => 40.7, :long => -73.5)
  end

  it 'sets radius when geo search is performed' do
    session.search Post do
      near [40.7, -73.5], 5
    end
    connection.should have_last_search_with(:radius => 5)
  end

  [
    [:lat, :lng],
    [:lat, :lon],
    [:lat, :long]
  ].each do |lat_attr, lng_attr|
    it "sets coordinates using #{lat_attr.inspect}, #{lng_attr.inspect}" do
      session.search Post do
        near OpenStruct.new(lat_attr => 40.7, lng_attr => -73.5), 5
      end
      connection.should have_last_search_with(:lat => 40.7, :long => -73.5)
    end
  end
end
