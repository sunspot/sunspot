require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'stats', :type => :search do
  it 'returns field name for stats field' do
    stub_stats(:average_rating_ft, {})
    result = session.search Post do
      stats :average_rating
    end
    result.stats(:average_rating).field_name.should == :average_rating
  end

  it 'returns min for stats field' do
    stub_stats(:average_rating_ft, { 'min' => 1.0 })
    result = session.search Post do
      stats :average_rating
    end
    result.stats(:average_rating).min.should == 1.0
  end

  it 'returns max for stats field' do
    stub_stats(:average_rating_ft, { 'max' => 5.0 })
    result = session.search Post do
      stats :average_rating
    end
    result.stats(:average_rating).max.should == 5.0
  end

  it 'returns count for stats field' do
    stub_stats(:average_rating_ft, { 'count' => 120 })
    result = session.search Post do
      stats :average_rating
    end
    result.stats(:average_rating).count.should == 120
  end

  it 'returns sum for stats field' do
    stub_stats(:average_rating_ft, { 'sum' => 2200.0 })
    result = session.search Post do
      stats :average_rating
    end
    result.stats(:average_rating).sum.should == 2200.0
  end

  it 'returns facet rows for stats field' do
    stub_stats_facets(:average_rating_ft, 'featured_bs' => {
      'false' => {},
      'true' => {}
    })
    result = session.search Post do
      stats :average_rating do
        facet :featured
      end
    end
    stats_facet_values(result, :average_rating, :featured).should == %w{ false true }
  end

  it 'returns facet stats for stats field' do
    stub_stats_facets(:average_rating_ft, 'featured_bs' => {
      'true' => { 'min' => 2.0, 'max' => 4.0 }
    })
    result = session.search Post do
      stats :average_rating do
        facet :featured
      end
    end
    stats_facet_stats(result, :average_rating, :featured, 'true').min.should == 2.0
    stats_facet_stats(result, :average_rating, :featured, 'true').max.should == 4.0
  end
end
