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

  it 'puts all scope parameters into :q parameter when geo search is performed' do
    session.search Post do
      with :blog_id, 1
      near [40.7, -73.5], 5
    end
    connection.should have_last_search_with(:q => '(type:Post AND blog_id_i:1)')
  end

  it 'raises error if keywords specified in local search' do
    lambda do
      session.search Post do
        keywords 'fail'
        near [40.7, -73.5], 5
      end
    end.should raise_error(Sunspot::IllegalSearchError)
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

  it 'raises ArgumentError if radius is less than 1' do
    lambda do
      session.search Post do
        near [40, -70], 0.5
      end
    end.should raise_error(ArgumentError)
  end
end
