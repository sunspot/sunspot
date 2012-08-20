shared_examples_for "query with connective scope" do
  it 'creates a disjunction between two restrictions' do
    search do
      any_of do
        with :category_ids, 1
        with :blog_id, 2
      end
    end
    connection.should have_last_search_including(
      :fq, '(category_ids_im:1 OR blog_id_i:2)'
    )
  end

  it 'creates a conjunction inside of a disjunction' do
    search do
      any_of do
        with :blog_id, 2
        all_of do
          with :category_ids, 1
          with(:average_rating).greater_than(3.0)
        end
      end
    end
    connection.should have_last_search_including(
      :fq,
      '(blog_id_i:2 OR (category_ids_im:1 AND average_rating_ft:{3\.0 TO *}))'
    )
  end

  it 'creates a disjunction with nested conjunction with negated restrictions' do
    search do
      any_of do
        with :category_ids, 1
        all_of do
          without(:average_rating).greater_than(3.0)
          with(:blog_id, 1)
        end
      end
    end
    connection.should have_last_search_including(
      :fq, '(category_ids_im:1 OR (-average_rating_ft:{3\.0 TO *} AND blog_id_i:1))'
    )
  end

  it 'does nothing special if #all_of called from the top level' do
    search do
      all_of do
        with :blog_id, 2
        with :category_ids, 1
      end
    end
    connection.should have_last_search_including(
      :fq, 'blog_id_i:2', 'category_ids_im:1'
    )
  end

  it 'creates a disjunction with negated restrictions' do
    search do
      any_of do
        with :category_ids, 1
        without(:average_rating).greater_than(3.0)
      end
    end
    connection.should have_last_search_including(
      :fq, '-(-category_ids_im:1 AND average_rating_ft:{3\.0 TO *})'
    )
  end

  it 'creates a disjunction with a negated restriction and a nested disjunction in a conjunction with a negated restriction' do
    search do
      any_of do
        without(:title, 'Yes')
        all_of do
          with(:blog_id, 1)
          any_of do
            with(:category_ids, 4)
            without(:average_rating, 2.0)
          end
        end
      end
    end
    connection.should have_last_search_including(
      :fq, '-(title_ss:Yes AND -(blog_id_i:1 AND -(-category_ids_im:4 AND average_rating_ft:2\.0)))'
    )
  end
  it 'creates a disjunction with nested conjunction with nested disjunction with negated restriction' do
    search do
      any_of do
        with(:title, 'Yes')
        all_of do
          with(:blog_id, 1)
          any_of do
            with(:category_ids, 4)
            without(:average_rating, 2.0)
          end
        end
      end
    end
    connection.should have_last_search_including(
      :fq, '(title_ss:Yes OR (blog_id_i:1 AND -(-category_ids_im:4 AND average_rating_ft:2\.0)))'
    )
  end

  #
  # This is important because if a disjunction could be nested in another
  # disjunction, then the inner disjunction could denormalize (and thus
  # become negated) after the outer disjunction denormalized (checking to
  # see if the inner one is negated). Since conjunctions never need to
  # denormalize, if a disjunction can only contain conjunctions or restrictions,
  # we can guarantee that the negation state of a disjunction's components will
  # not change when #to_params is called on them.
  #
  # Since disjunction is associative, this behavior has no effect on the actual
  # logical semantics of the disjunction.
  #
  it 'creates a single disjunction when disjunctions nested' do
    search do
      any_of do
        with(:title, 'Yes')
        any_of do
          with(:blog_id, 1)
          with(:category_ids, 4)
        end
      end
    end
    connection.should have_last_search_including(
      :fq, '(title_ss:Yes OR blog_id_i:1 OR category_ids_im:4)'
    )
  end

  it 'creates a disjunction with instance exclusion' do
    post = Post.new
    search do
      any_of do
        without(post)
        with(:category_ids, 1)
      end
    end
    connection.should have_last_search_including(
      :fq, "-(id:(Post\\ #{post.id}) AND -category_ids_im:1)"
    )
  end

  it 'creates a disjunction with empty restriction' do
    search do
      any_of do
        with(:average_rating, nil)
        with(:average_rating).greater_than(3.0)
      end
    end
    connection.should have_last_search_including(
      :fq, '-(average_rating_ft:[* TO *] AND -average_rating_ft:{3\.0 TO *})'
    )
  end

  it 'creates a disjunction with instance inclusion' do
    post = Post.new
    search do
      any_of do
        with(post)
        with(:average_rating).greater_than(3.0)
      end
    end
    connection.should have_last_search_including(
      :fq, "(id:(Post\\ #{post.id}) OR average_rating_ft:{3\\.0 TO *})"
    )
  end

  it 'creates a disjunction with some text field components' do
    search do
      any_of do
        text_fields do
          with(:title).starting_with('test')
        end
        with(:blog_id, 1)
      end
    end
    connection.should have_last_search_including(
      :fq, '(title_text:test* OR blog_id_i:1)'
    )
  end

  it 'should ignore empty connectives' do
    search do
      any_of {}
    end
    connection.should_not have_last_search_including(:fq, '')
  end

  it 'creates a conjunction of in_radius queries' do
    search do
      any_of do
        with(:coordinates_new).in_radius(23, -46, 100)
        with(:coordinates_new).in_radius(42, 56, 50)
      end
    end
    connection.should have_last_search_including(
      :fq, '(_query_:"{!geofilt sfield=coordinates_new_ll pt=23,-46 d=100}" OR _query_:"{!geofilt sfield=coordinates_new_ll pt=42,56 d=50}")'
    )
  end
end
