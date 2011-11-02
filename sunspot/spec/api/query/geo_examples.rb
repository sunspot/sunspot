require 'bigdecimal'

shared_examples_for 'geohash query' do
  it 'searches for nearby points with defaults' do
    search do
      with(:coordinates).near(40.7, -73.5)
    end
    connection.should have_last_search_including(:q, build_geo_query)
  end

  it 'searches for nearby points with non-Float arguments' do
    search do
      with(:coordinates).near(BigDecimal.new('40.7'), BigDecimal.new('-73.5'))
    end
    connection.should have_last_search_including(:q, build_geo_query)
  end

  it 'searches for nearby points with given precision' do
    search do
      with(:coordinates).near(40.7, -73.5, :precision => 10)
    end
    connection.should have_last_search_including(:q, build_geo_query(:precision => 10))
  end

  it 'searches for nearby points with given precision factor' do
    search do
      with(:coordinates).near(40.7, -73.5, :precision_factor => 1.5)
    end
    connection.should have_last_search_including(:q, build_geo_query(:precision_factor => 1.5))
  end

  it 'searches for nearby points with given boost' do
    search do
      with(:coordinates).near(40.7, -73.5, :boost => 2.0)
    end
    connection.should have_last_search_including(:q, build_geo_query(:boost => 2.0))
  end

  it 'performs both dismax search and location search' do
    search do
      fulltext 'pizza', :fields => :title
      with(:coordinates).near(40.7, -73.5)
    end
    expected = 
      "{!dismax fl='* score' qf='title_text'}pizza (#{build_geo_query})"
    connection.should have_last_search_including(
      :q,
      %Q(_query_:"{!dismax qf='title_text'}pizza" (#{build_geo_query}))
    )
  end

  private

  def build_geo_query(options = {})
    precision = options[:precision] || 7
    precision_factor = options[:precision_factor] || 16.0
    boost = options[:boost] || 1.0
    hash = 'dr5xx3nytvgs'
    (precision..12).map do |i|
      phrase = 
        if i == 12 then hash
        else "#{hash[0, i]}*"
        end
      precision_boost = Sunspot::Util.format_float(boost*precision_factor**(i-12.0), 3)
      "coordinates_s:#{phrase}^#{precision_boost}"
    end.reverse.join(' OR ')
  end
end
