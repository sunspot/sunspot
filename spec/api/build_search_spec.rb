require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Search' do
  it 'should search by keywords from DSL' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:q => 'keyword search')
  end

  it 'should search by keywords from options' do
    session.search Post, :keywords => 'keyword search'
    connection.should have_last_search_with(:q => 'keyword search')
  end

  it 'should set default query parser to dismax when keywords used' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:defType => 'dismax')
  end

  it 'should search types in filter query if keywords used' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:fq => 'type:Post')
  end

  it 'should search types in main query if keywords not used' do
    session.search Post
    connection.should have_last_search_with(:q => 'type:Post')
  end

  it 'should search type of subclass when superclass is configured' do
    session.search PhotoPost
    connection.should have_last_search_with(:q => 'type:PhotoPost')
  end

  it 'should search all text fields for searched class' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_text title_text)
  end

  it 'should search only specified text fields when specified' do
    session.search Post do
      keywords 'keyword search', :fields => [:title, :body]
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_text title_text)
  end

  it 'should request score when keywords used' do
    session.search Post, :keywords => 'keyword search'
    connection.should have_last_search_with(:fl => '* score')
  end

  it 'should not request score when keywords not used' do
    session.search Post
    connection.should_not have_last_search_with(:fl)
  end

  it 'should scope by exact match with a string from DSL' do
    session.search Post do
      with :title, 'My Pet Post'
    end
    connection.should have_last_search_with(:fq => ['title_ss:My\ Pet\ Post'])
  end

  it 'should scope by exact match with a string from options' do
    session.search Post, :conditions => { :title => 'My Pet Post' }
    connection.should have_last_search_with(:fq => ['title_ss:My\ Pet\ Post'])
  end

  it 'should ignore nonexistant fields in hash scope' do
    session.search Post, :conditions => { :bogus => 'Field' }
    connection.should_not have_last_search_with(:fq)
  end

  it 'should scope by exact match with time' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post do
      with :published_at, time
    end
    connection.should have_last_search_with(
      :fq => ['published_at_d:1983\-07\-08T09\:00\:00Z']
    )
  end

  it 'should scope by exact match with date' do
    date = Date.new(1983, 7, 8)
    session.search Post do
      with :expire_date, date
    end
    connection.should have_last_search_with(
      :fq => ['expire_date_d:1983\-07\-08T00\:00\:00Z']
    )
  end
  
  it 'should scope by exact match with boolean' do
    session.search Post do
      with :featured, false
    end
    connection.should have_last_search_with(:fq => ['featured_b:false'])
  end

  it 'should scope by less than match with float' do
    session.search Post do
      with(:average_rating).less_than 3.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[* TO 3\.0]'])
  end

  it 'should scope by greater than match with float' do
    session.search Post do
      with(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[3\.0 TO *]'])
  end

  it 'should scope by short-form between match with integers' do
    session.search Post do
      with :blog_id, 2..4
    end
    connection.should have_last_search_with(:fq => ['blog_id_i:[2 TO 4]'])
  end

  it 'should scope by between match with float' do
    session.search Post do
      with(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[2\.0 TO 4\.0]'])
  end

  it 'should scope by any match with integer using DSL' do
    session.search Post do
      with(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should scope by any match with integer using options' do
    session.search Post, :conditions => { :category_ids => [2, 7, 12] }
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should scope by short-form any-of match with integers' do
    session.search Post do
      with :category_ids, [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should scope by all match with integer' do
    session.search Post do
      with(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 AND 7 AND 12)'])
  end

  it 'should scope by not equal match with string' do
    session.search Post do
      without :title, 'Bad Post'
    end
    connection.should have_last_search_with(:fq => ['-title_ss:Bad\ Post'])
  end

  it 'should scope by not less than match with float' do
    session.search Post do
      without(:average_rating).less_than 3.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[* TO 3\.0]'])
  end

  it 'should scope by not greater than match with float' do
    session.search Post do
      without(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[3\.0 TO *]'])
  end
  
  it 'should scope by not between match with shorthand' do
    session.search Post do
      without(:blog_id, 2..4)
    end
    connection.should have_last_search_with(:fq => ['-blog_id_i:[2 TO 4]'])
  end

  it 'should scope by not between match with float' do
    session.search Post do
      without(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[2\.0 TO 4\.0]'])
  end

  it 'should scope by not any match with integer' do
    session.search Post do
      without(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['-category_ids_im:(2 OR 7 OR 12)'])
  end


  it 'should scope by not all match with integer' do
    session.search Post do
      without(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['-category_ids_im:(2 AND 7 AND 12)'])
  end

  it 'should scope by empty field' do
    session.search Post do
      with :average_rating, nil
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[* TO *]'])
  end

  it 'should scope by non-empty field' do
    session.search Post do
      without :average_rating, nil
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[* TO *]'])
  end

  it 'should exclude by object identity' do
    post = Post.new
    session.search Post do
      without post
    end
    connection.should have_last_search_with(:fq => ["-id:Post\\ #{post.id}"])
  end

  it 'should exclude multiple objects passed as varargs by object identity' do
    post1, post2 = Post.new, Post.new
    session.search Post do
      without post1, post2
    end
    connection.should have_last_search_with(
      :fq => ["-id:Post\\ #{post1.id}", "-id:Post\\ #{post2.id}"]
    )
  end

  it 'should exclude multiple objects passed as array by object identity' do
    posts = [Post.new, Post.new]
    session.search Post do
      without posts
    end
    connection.should have_last_search_with(
      :fq => ["-id:Post\\ #{posts.first.id}", "-id:Post\\ #{posts.last.id}"]
    )
  end

  it 'should create a disjunction between two restrictions' do
    session.search Post do
      any_of do
        with :category_ids, 1
        with :blog_id, 2
      end
    end
    connection.should have_last_search_with(
      :fq => '(category_ids_im:1 OR blog_id_i:2)'
    )
  end

  it 'should create a conjunction inside of a disjunction' do
    session.search Post do
      any_of do
        with :blog_id, 2
        all_of do
          with :category_ids, 1
          with(:average_rating).greater_than(3.0)
        end
      end
    end
    connection.should have_last_search_with(
      :fq => '(blog_id_i:2 OR (category_ids_im:1 AND average_rating_f:[3\.0 TO *]))'
    )
  end

  it 'should do nothing special if #all_of called from the top level' do
    session.search Post do
      all_of do
        with :blog_id, 2
        with :category_ids, 1
      end
    end
    connection.should have_last_search_with(
      :fq => ['blog_id_i:2', 'category_ids_im:1']
    )
  end

  it 'should create a disjunction with negated restrictions' do
    session.search Post do
      any_of do
        with :category_ids, 1
        without(:average_rating).greater_than(3.0)
      end
    end
    connection.should have_last_search_with(
      :fq => '-(-category_ids_im:1 AND average_rating_f:[3\.0 TO *])'
    )
  end

  it 'should create a disjunction with nested conjunction with negated restrictions' do
    session.search Post do
      any_of do
        with :category_ids, 1
        all_of do
          without(:average_rating).greater_than(3.0)
          with(:blog_id, 1)
        end
      end
    end
    connection.should have_last_search_with(
      :fq => '(category_ids_im:1 OR (-average_rating_f:[3\.0 TO *] AND blog_id_i:1))'
    )
  end

  it 'should create a disjunction with nested conjunction with nested disjunction with negated restriction' do
    session.search(Post) do
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
    connection.should have_last_search_with(
      :fq => '(title_ss:Yes OR (blog_id_i:1 AND -(-category_ids_im:4 AND average_rating_f:2\.0)))'
    )
  end

  it 'should create a disjunction with a negated restriction and a nested disjunction in a conjunction with a negated restriction' do
    session.search(Post) do
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
    connection.should have_last_search_with(
      :fq => '-(title_ss:Yes AND -(blog_id_i:1 AND -(-category_ids_im:4 AND average_rating_f:2\.0)))'
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
  it 'should create a single disjunction when disjunctions nested' do
    session.search(Post) do
      any_of do
        with(:title, 'Yes')
        any_of do
          with(:blog_id, 1)
          with(:category_ids, 4)
        end
      end
    end
    connection.should have_last_search_with(
      :fq => '(title_ss:Yes OR blog_id_i:1 OR category_ids_im:4)'
    )
  end

  it 'should create a disjunction with instance exclusion' do
    post = Post.new
    session.search Post do
      any_of do
        without(post)
        with(:category_ids, 1)
      end
    end
    connection.should have_last_search_with(
      :fq => "-(id:Post\\ #{post.id} AND -category_ids_im:1)"
    )
  end

  it 'should create a disjunction with empty restriction' do
    session.search Post do
      any_of do
        with(:average_rating, nil)
        with(:average_rating).greater_than(3.0)
      end
    end
    connection.should have_last_search_with(
      :fq => '-(average_rating_f:[* TO *] AND -average_rating_f:[3\.0 TO *])'
    )
  end

  it 'should restrict by dynamic string field with equality restriction' do
    session.search Post do
      dynamic :custom_string do
        with :test, 'string'
      end
    end
    connection.should have_last_search_with(:fq => ['custom_string\:test_s:string'])
  end

  it 'should restrict by dynamic integer field with less than restriction' do
    session.search Post do
      dynamic :custom_integer do
        with(:test).less_than(1)
      end
    end
    connection.should have_last_search_with(:fq => ['custom_integer\:test_i:[* TO 1]'])
  end

  it 'should restrict by dynamic float field with between restriction' do
    session.search Post do
      dynamic :custom_float do
        with(:test).between(2.2..3.3)
      end
    end
    connection.should have_last_search_with(:fq => ['custom_float\:test_fm:[2\.2 TO 3\.3]'])
  end

  it 'should restrict by dynamic time field with any of restriction' do
    session.search Post do
      dynamic :custom_time do
        with(:test).any_of([Time.parse('2009-02-10 14:00:00 UTC'),
                            Time.parse('2009-02-13 18:00:00 UTC')])
      end
    end
    connection.should have_last_search_with(:fq => ['custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)'])
  end

  it 'should restrict by dynamic boolean field with equality restriction' do
    session.search Post do
      dynamic :custom_boolean do
        with :test, false
      end
    end
    connection.should have_last_search_with(:fq => ['custom_boolean\:test_b:false'])
  end

  it 'should negate a dynamic field restriction' do
    session.search Post do
      dynamic :custom_string do
        without :test, 'foo'
      end
    end
    connection.should have_last_search_with(:fq => ['-custom_string\:test_s:foo'])
  end

  it 'should search by a dynamic field inside a disjunction' do
    session.search Post do
      any_of do
        dynamic :custom_string do
          with :test, 'foo'
        end
        with :title, 'bar'
      end
    end
    connection.should have_last_search_with(
      :fq => '(custom_string\:test_s:foo OR title_ss:bar)'
    )
  end

  it 'should throw an UnrecognizedFieldError if an unknown dynamic field is searched by' do
    lambda do
      session.search Post do
        dynamic(:bogus) { with :some, 'value' }
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should throw a NoMethodError if pagination is attempted in a dynamic query' do
    lambda do
      session.search Post do
        dynamic :custom_string do
          paginate 3, 10
        end
      end
    end.should raise_error(NoMethodError)
  end

  it 'should paginate using default per_page when page not provided' do
    session.search Post
    connection.should have_last_search_with(:rows => 30)
  end

  it 'should paginate using default per_page when page provided in DSL' do
    session.search Post do
      paginate :page => 2
    end
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'should paginate using default per_page when page provided in options' do
    session.search Post, :page => 2
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'should paginate using provided per_page in DSL' do
    session.search Post do
      paginate :page => 4, :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'should paginate using provided per_page in options' do
    session.search Post, :page => 4, :per_page => 15
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'should order in DSL' do
    session.search Post do
      order_by :average_rating, :desc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'should order in keywords' do
    session.search Post, :order => 'average_rating desc'
    connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'should order by multiple fields in DSL' do
    session.search Post do
      order_by :average_rating, :desc
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc, sort_title_s asc')
  end

  it 'should order by multiple fields in options' do
    session.search Post, :order => ['average_rating desc', 'sort_title asc']
    connection.should have_last_search_with(:sort => 'average_rating_f desc, sort_title_s asc')
  end

  it 'should order by a dynamic field' do
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc')
  end

  it 'should order by a dynamic field and static field, with given precedence' do
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc, sort_title_s asc')
  end

  it 'should order by random' do
    session.search Post do
      order_by_random
    end
    connection.searches.last[:sort].should =~ /^random_\d+ asc$/
  end

  it 'should throw an ArgumentError if a bogus order direction is given' do
    lambda do
      session.search Post do
        order_by :sort_title, :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'should not allow ordering by multiple-value fields' do
    lambda do
      session.search Post do
        order_by :category_ids
      end
    end.should raise_error(ArgumentError)
  end

  it 'should not turn faceting on if no facet requested' do
    session.search(Post)
    connection.should_not have_last_search_with('facet')
  end

  it 'should turn faceting on if facet is requested' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with(:facet => 'true')
  end

  it 'should request single field facet' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with(:"facet.field" => %w(category_ids_im))
  end

  it 'should request multiple field facets' do
    session.search Post do
      facet :category_ids, :blog_id
    end
    connection.should have_last_search_with(:"facet.field" => %w(category_ids_im blog_id_i))
  end

  it 'should set facet sort by count' do
    session.search Post do
      facet :category_ids, :sort => :count
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'true')
  end

  it 'should set facet sort by index' do
    session.search Post do
      facet :category_ids, :sort => :index
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'false')
  end

  it 'should throw ArgumentError if bogus facet sort provided' do
    lambda do
      session.search Post do
        facet :category_ids, :sort => :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'should set the facet limit' do
    session.search Post do
      facet :category_ids, :limit => 10
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.limit" => 10)
  end

  it 'should set the facet minimum count' do
    session.search Post do
      facet :category_ids, :minimum_count => 5
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 5)
  end

  it 'should set the facet minimum count to zero if zeros are allowed' do
    session.search Post do
      facet :category_ids, :zeros => true
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 0)
  end

  it 'should set the facet minimum count to one by default' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 1)
  end

  describe 'with date faceting' do
    before :each do
      @time_range = (Time.parse('2009-06-01 00:00:00 -0400')..
                     Time.parse('2009-07-01 00:00:00 -0400'))
    end

    it 'should not send date facet parameters if time range is not specified' do
      session.search Post do |query|
        query.facet :published_at
      end
      connection.should_not have_last_search_with(:"facet.date")
    end

    it 'should set the facet to a date facet' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"facet.date" => ['published_at_d'])
    end

    it 'should set the facet start and end' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(
        :"f.published_at_d.facet.date.start" => '2009-06-01T04:00:00Z',
        :"f.published_at_d.facet.date.end" => '2009-07-01T04:00:00Z'
      )
    end

    it 'should default the time interval to 1 day' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.gap" => "+86400SECONDS")
    end

    it 'should use custom time interval' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range, :time_interval => 3600
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.gap" => "+3600SECONDS")
    end

    it 'should not allow date faceting on a non-date field' do
      lambda do
        session.search Post do |query|
          query.facet :blog_id, :time_range => @time_range
        end
      end.should raise_error(ArgumentError)
    end
  end

  describe 'with query faceting' do
    it 'should turn faceting on' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:facet => 'true')
    end

    it 'should facet by query' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:"facet.query" => 'average_rating_f:[4\.0 TO 5\.0]')
    end

    it 'should request multiple query facets' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(3.0..4.0)
          end
          row :baz do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => [
          'average_rating_f:[3\.0 TO 4\.0]',
          'average_rating_f:[4\.0 TO 5\.0]'
        ]
      )
    end

    it 'should request query facet with multiple conditions' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:category_ids, 1)
            with(:blog_id, 2)
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => '(category_ids_im:1 AND blog_id_i:2)'
      )
    end

    it 'should request query facet with disjunction' do
      session.search Post do
        facet :foo do
          row :bar do
            any_of do
              with(:category_ids, 1)
              with(:blog_id, 2)
            end
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => '(category_ids_im:1 OR blog_id_i:2)'
      )
    end

    it 'should request query facet with internal dynamic field' do
      session.search Post do
        facet :test do
          row 'foo' do
            dynamic :custom_string do
              with :test, 'foo'
            end
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => 'custom_string\:test_s:foo'
      )
    end

    it 'should request query facet with external dynamic field' do
      session.search Post do
        dynamic :custom_string do
          facet :test do
            row 'foo' do
              with :test, 'foo'
            end
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => 'custom_string\:test_s:foo'
      )
    end

    it 'should not allow 0 arguments to facet method with block' do
      lambda do
        session.search Post do
          facet do
          end
        end
      end.should raise_error(ArgumentError)
    end

    it 'should not allow more than 1 argument to facet method with block' do
      lambda do
        session.search Post do
          facet :foo, :bar do
          end
        end
      end.should raise_error(ArgumentError)
    end
  end

  it 'builds query facets when passed :only argument to field facet declaration' do
    session.search Post do
      facet :category_ids, :only => [1, 3]
    end
    connection.should have_last_search_with(
      :"facet.query" => ['category_ids_im:1', 'category_ids_im:3']
    )
  end

  it 'converts limited query facet values to the correct type' do
    session.search Post do
      facet :published_at, :only => [Time.utc(2009, 8, 28, 15, 33), Time.utc(2008,8, 28, 15, 33)]
    end
    connection.should have_last_search_with(
      :"facet.query" => [
        'published_at_d:2009\-08\-28T15\:33\:00Z',
        'published_at_d:2008\-08\-28T15\:33\:00Z'
    ]
    )
  end

  it 'should allow faceting by dynamic string field' do
    session.search Post do
      dynamic :custom_string do
        facet :test
      end
    end
    connection.should have_last_search_with(:"facet.field" => %w(custom_string:test_s))
  end

  it 'should properly escape namespaced type names' do
    session.search(Namespaced::Comment)
    connection.should have_last_search_with(:q => 'type:Namespaced\:\:Comment')
  end

  it 'should build search for multiple types' do
    session.search(Post, Namespaced::Comment)
    connection.should have_last_search_with(:q => 'type:(Post OR Namespaced\:\:Comment)')
  end

  it 'should allow search on fields common to all types with DSL' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, Namespaced::Comment do
      with :published_at, time
    end
    connection.should have_last_search_with(:fq => ['published_at_d:1983\-07\-08T09\:00\:00Z'])
  end

  it 'should allow search on fields common to all types with conditions' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, Namespaced::Comment, :conditions => { :published_at => time }
    connection.should have_last_search_with(:fq => ['published_at_d:1983\-07\-08T09\:00\:00Z'])
  end

  it 'should allow search on dynamic fields common to all types' do
    session.search Post, Namespaced::Comment do
      dynamic :custom_string do
        with(:test, 'test')
      end
    end
    connection.should have_last_search_with(:fq => ['custom_string\\:test_s:test'])
  end

  it 'should combine all text fields' do
    session.search Post, Namespaced::Comment do
      keywords 'keywords'
    end
    connection.searches.last[:qf].split(' ').sort.should == 
      %w(author_name_text backwards_title_text body_text title_text)
  end

  it 'should allow specification of a text field that only exists in one type' do
    session.search Post, Namespaced::Comment do
      keywords 'keywords', :fields => :author_name
    end
    connection.searches.last[:qf].should == 'author_name_text'
  end

  it 'should raise Sunspot::UnrecognizedFieldError if search scoped to field not common to all types' do
    lambda do
      session.search Post, Namespaced::Comment do
        with :blog_id, 1
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise Sunspot::UnrecognizedFieldError if search scoped to field configured differently between types' do
    lambda do
      session.search Post, Namespaced::Comment do
        with :average_rating, 2.2 # this is a float in Post but an integer in Comment
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise Sunspot::UnrecognizedFieldError if a text field that does not exist for any type is specified' do
    lambda do
      session.search Post, Namespaced::Comment do
        keywords 'fulltext', :fields => :bogus
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should ignore condition if field is not common to all types' do
    session.search Post, Namespaced::Comment, :conditions => { :blog_id => 1 }
    connection.should_not have_last_search_with(:fq)
  end

  it 'should allow building search using block argument rather than instance_eval' do
    @blog_id = 1
    session.search Post do |query|
      query.with(:blog_id, @blog_id)
    end
    connection.should have_last_search_with(:fq => ['blog_id_i:1'])
  end

  it 'should raise Sunspot::UnrecognizedFieldError for nonexistant fields in block scope' do
    lambda do
      session.search Post do
        with :bogus, 'Field'
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise Sunspot::UnrecognizedFieldError for nonexistant fields in keywords' do
    lambda do
      session.search Post do
        keywords 'text', :fields => :bogus
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise NoMethodError if bogus operator referenced' do
    lambda do
      session.search Post do
        with(:category_ids).resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  it 'should raise ArgumentError if no :page argument given to paginate' do
    lambda do
      session.search Post do
        paginate
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise ArgumentError if bogus argument given to paginate' do
    lambda do
      session.search Post do
        paginate :page => 4, :ugly => :puppy
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise ArgumentError if more than two arguments passed to scope method' do
    lambda do
      session.search Post do
        with(:category_ids, 4, 5)
      end
    end.should raise_error(ArgumentError)
  end

  private

  def config
    @config ||= Sunspot::Configuration.build
  end

  def connection
    @connection ||= Mock::Connection.new
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end
end
