require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'stats', :type => :search do
  it 'returns field name for stats field' do
    stub_stats(:average_rating_ft, {})
    result = session.search Post do
      stats :average_rating
    end
    expect(result.stats(:average_rating).field_name).to eq(:average_rating)
  end

  it 'returns min for stats field' do
    stub_stats(:average_rating_ft, { 'min' => 1.0 })
    result = session.search Post do
      stats :average_rating
    end
    expect(result.stats(:average_rating).min).to eq(1.0)
  end

  it 'returns max for stats field' do
    stub_stats(:average_rating_ft, { 'max' => 5.0 })
    result = session.search Post do
      stats :average_rating
    end
    expect(result.stats(:average_rating).max).to eq(5.0)
  end

  it 'returns count for stats field' do
    stub_stats(:average_rating_ft, { 'count' => 120 })
    result = session.search Post do
      stats :average_rating
    end
    expect(result.stats(:average_rating).count).to eq(120)
  end

  it 'returns sum for stats field' do
    stub_stats(:average_rating_ft, { 'sum' => 2200.0 })
    result = session.search Post do
      stats :average_rating
    end
    expect(result.stats(:average_rating).sum).to eq(2200.0)
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
    expect(stats_facet_values(result, :average_rating, :featured)).to eq([false, true])
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
    expect(stats_facet_stats(result, :average_rating, :featured, true).min).to eq(2.0)
    expect(stats_facet_stats(result, :average_rating, :featured, true).max).to eq(4.0)
  end

  it 'returns instantiated stats facet values' do
    blogs = 2.times.map { Blog.new }
    stub_stats_facets(:average_rating_ft, 'blog_id_i' => {
      blogs[0].id.to_s => {}, blogs[1].id.to_s => {} })
    search = session.search(Post) do
      stats :average_rating do
        facet :blog_id
      end
    end
    expect(search.stats(:average_rating).facet(:blog_id).rows.map { |row| row.instance }).to eq(blogs)
  end

  it 'only returns verified instances when requested' do
    blog = Blog.new
    stub_stats_facets(:average_rating_ft, 'blog_id_i' => {
      blog.id.to_s => {}, '0' => {} })

    search = session.search(Post) do
      stats :average_rating do
        facet :blog_id
      end
    end
    expect(search.stats(:average_rating).facet(:blog_id).rows(:verified => true).map { |row| row.instance }).to eq([blog])
  end
end
