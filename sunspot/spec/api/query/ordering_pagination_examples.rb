shared_examples_for 'sortable query' do
  it 'paginates using default per_page when page not provided' do
    search
    connection.should have_last_search_with(:rows => 30)
  end

  it 'paginates using default per_page when page provided' do
    search do
      paginate :page => 2
    end
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'paginates using provided per_page' do
    search do
      paginate :page => 4, :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'defaults to page 1 if no :page argument given' do
    search do
      paginate :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 0)
  end

  it 'paginates with an offset' do
    search do
      paginate :per_page => 15, :offset => 3
    end
    connection.should have_last_search_with(:rows => 15, :start => 3)
  end

  it 'paginates with an offset as a string' do
    search do
      paginate :per_page => 15, :offset => '3'
    end
    connection.should have_last_search_with(:rows => 15, :start => 3)
  end

  it 'paginates from string argument' do
    search do
      paginate :page => '3', :per_page => '15'
    end
    connection.should have_last_search_with(:rows => 15, :start => 30)
  end

  it 'orders by a single field' do
    search do
      order_by :average_rating, :desc
    end
    connection.should have_last_search_with(:sort => 'average_rating_ft desc')
  end

  it 'orders by multiple fields' do
    search do
      order_by :average_rating, :desc
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'average_rating_ft desc, sort_title_s asc')
  end

  it 'orders by random' do
    search do
      order_by :random
    end
    connection.searches.last[:sort].should =~ /^random_\d+ asc$/
  end

  it 'orders by random with declared direction' do
    search do
      order_by :random, :desc
    end
    connection.searches.last[:sort].should =~ /^random_\d+ desc$/
  end

  it 'orders by random with provided seed value' do
    search do
      order_by :random, :seed => 9001
    end
    connection.searches.last[:sort].should =~ /^random_9001 asc$/
  end

  it 'orders by random with provided seed value and direction' do
    search do
      order_by :random, :seed => 12345, :direction => :desc
    end
    connection.searches.last[:sort].should =~ /^random_12345 desc$/
  end

  it 'orders by score' do
    search do
      order_by :score, :desc
    end
    connection.should have_last_search_with(:sort => 'score desc')
  end

  it 'orders by geodist' do
    search do
      order_by_geodist :coordinates_new, 32, -68, :desc
    end
    connection.should have_last_search_with(:sort => 'geodist(coordinates_new_ll,32,-68) desc')
  end

  it 'throws an ArgumentError if a bogus order direction is given' do
    lambda do
      search do
        order_by :sort_title, :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'throws an UnrecognizedFieldError if :distance is given for sort' do
    lambda do
      search do
        order_by :distance, :asc
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'does not allow ordering by multiple-value fields' do
    lambda do
      search do
        order_by :category_ids
      end
    end.should raise_error(ArgumentError)
  end

  it 'raises ArgumentError if bogus argument given to paginate' do
    lambda do
      search do
        paginate :page => 4, :ugly => :puppy
      end
    end.should raise_error(ArgumentError)
  end
end
