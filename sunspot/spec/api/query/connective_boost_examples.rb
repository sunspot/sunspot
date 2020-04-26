shared_examples_for "query with connective scope and boost" do
  it 'creates a boost query' do
    search do
      boost(10) do
        any_of do
          with(:coordinates_new).in_bounding_box([23, -46], [25, -44])
          with(:coordinates_new).in_bounding_box([42, 56], [43, 58])
        end
      end
    end

    expect(connection).to have_last_search_including(
      :bq, '(coordinates_new_ll:[23,-46 TO 25,-44] OR coordinates_new_ll:[42,56 TO 43,58])^10'
    )

    expect(connection).to have_last_search_including(
      :defType, 'edismax'
    )
  end

  it 'creates a boost function' do
    search do
      boost(function() { field(:average_rating) })
    end

    expect(connection).to have_last_search_including(
      :bf, 'field(average_rating_ft)'
    )

    expect(connection).to have_last_search_including(
      :defType, 'edismax'
    )
  end

  it 'creates a multiplicative boost function' do
    search do
      boost_multiplicative(function() { field(:average_rating) })
    end

    expect(connection).to have_last_search_including(
      :boost, 'field(average_rating_ft)'
    )

    expect(connection).to have_last_search_including(
      :defType, 'edismax'
    )
  end

  it 'creates combined boost search' do
    search do
      boost(10) do
        any_of do
          with(:coordinates_new).in_bounding_box([23, -46], [25, -44])
          with(:coordinates_new).in_bounding_box([42, 56], [43, 58])
        end
      end

      boost(function() { field(:average_rating) })
      boost_multiplicative(function() { field(:average_rating) })
    end

    expect(connection).to have_last_search_including(
      :bq, '(coordinates_new_ll:[23,-46 TO 25,-44] OR coordinates_new_ll:[42,56 TO 43,58])^10'
    )

    expect(connection).to have_last_search_including(
      :bf, 'field(average_rating_ft)'
    )

    expect(connection).to have_last_search_including(
      :boost, 'field(average_rating_ft)'
    )
  end

  it 'avoids duplicate boost functions' do
    search do
      boost(function() { field(:average_rating) })
      boost(function() { field(:average_rating) })
      boost_multiplicative(function() { field(:average_rating) })
    end

    expect(connection.searches.last[:bf]).to eq ['field(average_rating_ft)']
    expect(connection.searches.last[:boost]).to eq ['field(average_rating_ft)']
  end
end
