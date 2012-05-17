shared_examples_for "scoped query" do
  it 'scopes by exact match with a string' do
    search do
      with :title, 'My Pet Post'
    end
    connection.should have_last_search_including(:fq, 'title_ss:My\ Pet\ Post')
  end

  it 'scopes by exact match with a special string' do
    search do
      with :title, 'OR'
    end
    connection.should have_last_search_including(:fq, 'title_ss:"OR"')
  end

  it 'scopes by exact match with time' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    search do
      with :published_at, time
    end
    connection.should have_last_search_including(
      :fq,
      'published_at_dt:1983\-07\-08T09\:00\:00Z'
    )
  end

  it 'scopes by exact match with date' do
    date = Date.new(1983, 7, 8)
    search do
      with :expire_date, date
    end
    connection.should have_last_search_including(
      :fq,
      'expire_date_d:1983\-07\-08T00\:00\:00Z'
    )
  end
  
  it 'scopes by exact match with boolean' do
    search do
      with :featured, false
    end
    connection.should have_last_search_including(:fq, 'featured_bs:false')
  end

  it 'scopes by less than match with float' do
    search do
      with(:average_rating).less_than 3.0
    end
    connection.should have_last_search_including(:fq, 'average_rating_ft:{* TO 3\.0}')
  end

  it 'should quote string with space in a less than match' do
    search do
      with(:title).less_than('test value')
    end
    connection.should have_last_search_including(:fq, 'title_ss:{* TO "test\ value"}')
  end

  it 'scopes by greater than match with float' do
    search do
      with(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_including(:fq, 'average_rating_ft:{3\.0 TO *}')
  end

  it 'scopes by short-form between match with integers' do
    search do
      with :blog_id, 2..4
    end
    connection.should have_last_search_including(:fq, 'blog_id_i:[2 TO 4]')
  end

  it 'scopes by between match with float' do
    search do
      with(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_including(:fq, 'average_rating_ft:[2\.0 TO 4\.0]')
  end

  it 'scopes by any match with integer' do
    search do
      with(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_including(:fq, 'category_ids_im:(2 OR 7 OR 12)')
  end

  it 'scopes by short-form any-of match with integers' do
    search do
      with :category_ids, [2, 7, 12]
    end
    connection.should have_last_search_including(:fq, 'category_ids_im:(2 OR 7 OR 12)')
  end

  it 'scopes by all match with integer' do
    search do
      with(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_including(:fq, 'category_ids_im:(2 AND 7 AND 12)')
  end

  it 'scopes by prefix match with string' do
    search do
      with(:title).starting_with('tes')
    end
    connection.should have_last_search_including(:fq, 'title_ss:tes*')
  end

  it 'scopes by not equal match with string' do
    search do
      without :title, 'Bad Post'
    end
    connection.should have_last_search_including(:fq, '-title_ss:Bad\ Post')
  end

  it 'scopes by not less than match with float' do
    search do
      without(:average_rating).less_than 3.0
    end
    connection.should have_last_search_including(:fq, '-average_rating_ft:{* TO 3\.0}')
  end

  it 'scopes by not greater than match with float' do
    search do
      without(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_including(:fq, '-average_rating_ft:{3\.0 TO *}')
  end
  
  it 'scopes by not between match with shorthand' do
    search do
      without(:blog_id, 2..4)
    end
    connection.should have_last_search_including(:fq, '-blog_id_i:[2 TO 4]')
  end

  it 'scopes by not between match with float' do
    search do
      without(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_including(:fq, '-average_rating_ft:[2\.0 TO 4\.0]')
  end

  it 'scopes by not any match with integer' do
    search do
      without(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_including(:fq, '-category_ids_im:(2 OR 7 OR 12)')
  end

  it 'scopes by not all match with integer' do
    search do
      without(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_including(:fq, '-category_ids_im:(2 AND 7 AND 12)')
  end

  it 'scopes by empty field' do
    search do
      with :average_rating, nil
    end
    connection.should have_last_search_including(:fq, '-average_rating_ft:[* TO *]')
  end

  it 'scopes by non-empty field' do
    search do
      without :average_rating, nil
    end
    connection.should have_last_search_including(:fq, 'average_rating_ft:[* TO *]')
  end

  it 'includes by object identity' do
    post = Post.new
    search do
      with post
    end
    connection.should have_last_search_including(:fq, "id:(Post\\ #{post.id})")
  end

  it 'includes multiple objects passed as varargs by object identity' do
    post1, post2 = Post.new, Post.new
    search do
      with post1, post2
    end
    connection.should have_last_search_including(
      :fq, "id:(Post\\ #{post1.id} OR Post\\ #{post2.id})"
    )
  end

  it 'includes multiple objects passed as array by object identity' do
    posts = [Post.new, Post.new]
    search do
      with posts
    end
    connection.should have_last_search_including(
      :fq, "id:(Post\\ #{posts.first.id} OR Post\\ #{posts.last.id})"
    )
  end

  it 'excludes by object identity' do
    post = Post.new
    search do
      without post
    end
    connection.should have_last_search_including(:fq, "-id:(Post\\ #{post.id})")
  end

  it 'excludes multiple objects passed as varargs by object identity' do
    post1, post2 = Post.new, Post.new
    search do
      without post1, post2
    end
    connection.should have_last_search_including(
      :fq,
      "-id:(Post\\ #{post1.id} OR Post\\ #{post2.id})"
    )
  end

  it 'excludes multiple objects passed as array by object identity' do
    posts = [Post.new, Post.new]
    search do
      without posts
    end
    connection.should have_last_search_including(
      :fq,
      "-id:(Post\\ #{posts.first.id} OR Post\\ #{posts.last.id})"
    )
  end

  it 'allows scoping on fields common to all types' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    search Post, Namespaced::Comment do
      with :published_at, time
    end
    connection.should have_last_search_including(:fq, 'published_at_dt:1983\-07\-08T09\:00\:00Z')
  end

  it 'allows scoping on field not common to all types' do
    search Post, Namespaced::Comment do
      with :blog_id, 1
    end
    connection.should have_last_search_including(:fq, 'blog_id_i:1')
  end

  it 'raises Sunspot::UnrecognizedFieldError if search scoped to field configured differently between types' do
    lambda do
      search Post, Namespaced::Comment do
        with :average_rating, 2.2 # this is a float in Post but an integer in Comment
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'raises Sunspot::UnrecognizedFieldError for nonexistant fields in block scope' do
    lambda do
      search do
        with :bogus, 'Field'
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'raises NoMethodError if bogus operator referenced' do
    lambda do
      search do
        with(:category_ids).resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  it 'should raise ArgumentError if more than two arguments passed to scope method' do
    lambda do
      search do
        with(:category_ids, 4, 5)
      end
    end.should raise_error(ArgumentError)
  end
end
