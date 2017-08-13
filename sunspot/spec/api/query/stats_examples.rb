shared_examples_for 'stats query' do
  it 'does not use stats unless requested' do
    search
    expect(connection).not_to have_last_search_with(:stats)
  end

  it 'uses stats when requested' do
    search do
      stats :average_rating
    end
    expect(connection).to have_last_search_with(:stats => true)
  end

  it 'requests single field stats' do
    search do
      stats :average_rating
    end
    expect(connection).to have_last_search_with(:"stats.field" => %w{average_rating_ft})
  end

  it 'requests multiple field stats' do
    search do
      stats :average_rating, :published_at
    end
    expect(connection).to have_last_search_with(:"stats.field" => %w{average_rating_ft published_at_dt})
  end

  it 'facets on a stats field' do
    search do
      stats :average_rating do
        facet :featured
      end
    end
    expect(connection).to have_last_search_with(:"f.average_rating_ft.stats.facet" => %w{featured_bs})
  end

  it 'only facets on a stats field when requested' do
    search do
      stats :average_rating
    end
    expect(connection).not_to have_last_search_with(:"f.average_rating_ft.stats.facet")
  end

  it 'facets on multiple stats fields' do
    search do
      stats :average_rating, :published_at do
        facet :featured
      end
    end
    expect(connection).to have_last_search_with(
      :"f.average_rating_ft.stats.facet" => %w{featured_bs},
      :"f.published_at_dt.stats.facet" => %w{featured_bs}
    )
  end

  it 'supports facets on stats field' do
    search do
      stats :average_rating do
        facet :featured, :primary_category_id
      end
    end
    expect(connection).to have_last_search_with(
      :"f.average_rating_ft.stats.facet" => %w{featured_bs primary_category_id_i}
    )
  end
end
