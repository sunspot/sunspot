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
end
