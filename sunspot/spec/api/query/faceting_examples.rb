shared_examples_for "facetable query" do
  describe 'on fields' do
    it 'does not turn faceting on if no facet requested' do
      search
      connection.should_not have_last_search_with('facet')
    end

    it 'turns faceting on if facet is requested' do
      search do
        facet :category_ids
      end
      connection.should have_last_search_with(:facet => 'true')
    end

    it 'requests single field facet' do
      search do
        facet :category_ids
      end
      connection.should have_last_search_with(:"facet.field" => %w(category_ids_im))
    end

    it 'requests multiple field facets' do
      search do
        facet :category_ids, :blog_id
      end
      connection.should have_last_search_with(:"facet.field" => %w(category_ids_im blog_id_i))
    end

    it 'sets facet sort by count' do
      search do
        facet :category_ids, :sort => :count
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'true')
    end

    it 'sets facet sort by index' do
      search do
        facet :category_ids, :sort => :index
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'false')
    end

    it 'raises ArgumentError if bogus facet sort provided' do
      lambda do
        search do
          facet :category_ids, :sort => :sideways
        end
      end.should raise_error(ArgumentError)
    end

    it 'sets the facet limit' do
      search do
        facet :category_ids, :limit => 10
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.limit" => 10)
    end
    
    it 'sets the facet offset' do
      search do
        facet :category_ids, :offset => 10
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.offset" => 10)
    end

    it 'sets the facet minimum count' do
      search do
        facet :category_ids, :minimum_count => 5
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 5)
    end

    it 'sets the facet minimum count to zero if zeros are allowed' do
      search do
        facet :category_ids, :zeros => true
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 0)
    end

    it 'sets the facet minimum count to one by default' do
      search do
        facet :category_ids
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 1)
    end

    it 'sets the facet prefix' do
      search do
        facet :title, :prefix => 'Test'
      end
      connection.should have_last_search_with(:"f.title_ss.facet.prefix" => 'Test')
    end
    
    it 'sends a query facet for :any extra' do
      search do
        facet :category_ids, :extra => :any
      end
      connection.should have_last_search_with(:"facet.query" => "category_ids_im:[* TO *]")
    end

    it 'sends a query facet for :none extra' do
      search do
        facet :category_ids, :extra => :none
      end
      connection.should have_last_search_with(:"facet.query" => "-category_ids_im:[* TO *]")
    end

    it 'raises an ArgumentError if bogus extra is passed' do
      lambda do
        search do
          facet :category_ids, :extra => :bogus
        end
      end.should raise_error(ArgumentError)
    end

    it 'tags and excludes a scope filter in a field facet' do
      search do
        blog_filter = with(:blog_id, 1)
        facet(:blog_id, :exclude => blog_filter)
      end
      filter_tag = get_filter_tag('blog_id_i:1')
      connection.should have_last_search_with(
        :"facet.field" => %W({!ex=#{filter_tag}}blog_id_i)
      )
    end

    it 'tags and excludes a disjunction filter in a field facet' do
      search do
        blog_filter = any_of do
          with(:blog_id, 1)
          with(:blog_id, 2)
        end
        facet(:blog_id, :exclude => blog_filter)
      end
      filter_tag = get_filter_tag('(blog_id_i:1 OR blog_id_i:2)')
      connection.should have_last_search_with(
        :"facet.field" => %W({!ex=#{filter_tag}}blog_id_i)
      )
    end

    it 'tags and excludes multiple filters in a field facet' do
      search do
        blog_filter = with(:blog_id, 1)
        category_filter = with(:category_ids, 2)
        facet(:blog_id, :exclude => [blog_filter, category_filter])
      end
      filter_tags = %w(blog_id_i:1 category_ids_im:2).map do |phrase|
        get_filter_tag(phrase)
      end.join(',')
      connection.should have_last_search_with(
        :"facet.field" => %W({!ex=#{filter_tags}}blog_id_i)
      )
    end

    it 'does not tag a filter if it is not excluded' do
      search do
        with(:blog_id, 1)
      end
      connection.should have_last_search_including(:fq, "blog_id_i:1")
    end

    it 'names a field facet' do
      search do
        facet(:blog_id, :name => :blog)
      end
      connection.should have_last_search_including(:"facet.field", "{!key=blog}blog_id_i")
    end

    it 'uses the custom field facet name in facet option parameters' do
      search do
        facet(:blog_id, :name => :blog, :sort => :count)
      end
      connection.should have_last_search_with(:"f.blog.facet.sort" => 'true')
    end

    it 'raises an ArgumentError if exclusion attempted on a restricted field facet' do
      lambda do
        search do
          blog_filter = with(:blog_id, 1)
          facet(:blog_id, :only => 1, :exclude => blog_filter)
        end
      end.should raise_error(ArgumentError)
    end

    it 'raises an ArgumentError if exclusion attempted on a facet with :extra' do
      lambda do
        search do
          blog_filter = with(:blog_id, 1)
          facet(:blog_id, :extra => :all, :exclude => blog_filter)
        end
      end.should raise_error(ArgumentError)
    end
  end

  describe 'on time ranges' do
    before :each do
      @time_range = (Time.parse('2009-06-01 00:00:00 -0400')..
                     Time.parse('2009-07-01 00:00:00 -0400'))
    end

    it 'does not send date facet parameters if time range is not specified' do
      search do |query|
        query.facet :published_at
      end
      connection.should_not have_last_search_with(:"facet.date")
    end

    it 'sets the facet to a date facet if time range is specified' do
      search do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"facet.date" => ['published_at_dt'])
    end

    it 'sets the facet start and end' do
      search do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(
        :"f.published_at_dt.facet.date.start" => '2009-06-01T04:00:00Z',
        :"f.published_at_dt.facet.date.end" => '2009-07-01T04:00:00Z'
      )
    end

    it 'defaults the time interval to 1 day' do
      search do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"f.published_at_dt.facet.date.gap" => "+86400SECONDS")
    end

    it 'uses custom time interval' do
      search do |query|
        query.facet :published_at, :time_range => @time_range, :time_interval => 3600
      end
      connection.should have_last_search_with(:"f.published_at_dt.facet.date.gap" => "+3600SECONDS")
    end

    it 'does not allow date faceting on a non-date field' do
      lambda do
        search do |query|
          query.facet :blog_id, :time_range => @time_range
        end
      end.should raise_error(ArgumentError)
    end
  end

  describe 'on range facets' do
    before :each do
      @range = 2..4
    end

    it 'does not send range facet parameters if integer range is not specified' do
      search do |query|
        query.facet :average_rating
      end
      connection.should_not have_last_search_with(:"facet.range")
    end

    it 'sets the facet to a range facet if the range is specified' do
      search do |query|
        query.facet :average_rating, :range => @range
      end
      connection.should have_last_search_with(:"facet.range" => ['average_rating_ft'])
    end

    it 'sets the facet start and end' do
      search do |query|
        query.facet :average_rating, :range => @range
      end
      connection.should have_last_search_with(
        :"f.average_rating_ft.facet.range.start" => '2.0',
        :"f.average_rating_ft.facet.range.end" => '4.0'
      )
    end

    it 'defaults the range interval to 10' do
      search do |query|
        query.facet :average_rating, :range => @range
      end
      connection.should have_last_search_with(:"f.average_rating_ft.facet.range.gap" => "10")
    end

    it 'uses custom range interval' do
      search do |query|
        query.facet :average_rating, :range => @range, :range_interval => 1
      end
      connection.should have_last_search_with(:"f.average_rating_ft.facet.range.gap" => "1")
    end

    it 'tags and excludes a scope filter in a range facet' do
      search do |query|
        blog_filter = query.with(:blog_id, 1)
        query.facet(:average_rating, :range => @range, :exclude => blog_filter)
      end
      filter_tag = get_filter_tag('blog_id_i:1')
      connection.should have_last_search_with(
        :"facet.range" => %W({!ex=#{filter_tag}}average_rating_ft)
      )
    end

    it 'sets the include if one is specified' do
      search do |query|
        query.facet :average_rating, :range => @range, :include => :edge
      end
      connection.should have_last_search_with(:"f.average_rating_ft.facet.range.include" => "edge")
    end

    it 'does not allow date faceting on a non-continuous field' do
      lambda do
        search do |query|
          query.facet :title, :range => @range
        end
      end.should raise_error(ArgumentError)
    end
  end

  describe 'using queries' do
    it 'turns faceting on' do
      search do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:facet => 'true')
    end

    it 'facets by query' do
      search do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:"facet.query" => 'average_rating_ft:[4\.0 TO 5\.0]')
    end

    it 'requests multiple query facets' do
      search do
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
          'average_rating_ft:[3\.0 TO 4\.0]',
          'average_rating_ft:[4\.0 TO 5\.0]'
        ]
      )
    end

    it 'requests query facet with multiple conditions' do
      search do
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

    it 'requests query facet with disjunction' do
      search do
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

    it 'builds query facets when passed :only argument to field facet declaration' do
      search do
        facet :category_ids, :only => [1, 3]
      end
      connection.should have_last_search_with(
        :"facet.query" => ['category_ids_im:1', 'category_ids_im:3']
      )
    end

    it 'converts limited query facet values to the correct type' do
      search do
        facet :published_at, :only => [Time.utc(2009, 8, 28, 15, 33), Time.utc(2008,8, 28, 15, 33)]
      end
      connection.should have_last_search_with(
        :"facet.query" => [
          'published_at_dt:2009\-08\-28T15\:33\:00Z',
          'published_at_dt:2008\-08\-28T15\:33\:00Z'
        ]
      )
    end

    it 'ignores facet query with no rows' do
      search do
        facet(:foo) {}
      end
      connection.should_not have_last_search_with(:"facet.query")
    end

    it 'ignores facet query row with no restrictions' do
      search do
        facet :foo do
          row(:bar) do
            with(:blog_id, 1)
          end
          row(:baz) {}
        end
      end
      connection.searches.last[:"facet.query"].should be_a(String)
    end

    it 'tags and excludes a scope filter in a query facet' do
      search do
        blog_filter = with(:blog_id, 1)
        facet:foo, :exclude => blog_filter do
          row(:bar) do
            with(:category_ids, 1)
          end
        end
      end
      filter_tag = get_filter_tag('blog_id_i:1')
      connection.should have_last_search_with(
        :"facet.query" => "{!ex=#{filter_tag}}category_ids_im:1"
      )
    end

    it 'tags and excludes a disjunction filter in a query facet' do
      search do
        blog_filter = any_of do
          with(:blog_id, 1)
          with(:blog_id, 2)
        end
        facet:foo, :exclude => blog_filter do
          row(:bar) do
            with(:category_ids, 1)
          end
        end
      end
      filter_tag = get_filter_tag('(blog_id_i:1 OR blog_id_i:2)')
      connection.should have_last_search_with(
        :"facet.query" => "{!ex=#{filter_tag}}category_ids_im:1"
      )
    end

    it 'tags and excludes multiple filters in a query facet' do
      search do
        blog_filter = with(:blog_id, 1)
        category_filter = with(:category_ids, 2)
        facet:foo, :exclude => [blog_filter, category_filter] do
          row(:bar) do
            with(:category_ids, 1)
          end
        end
      end
      filter_tags = %w(blog_id_i:1 category_ids_im:2).map do |phrase|
        get_filter_tag(phrase)
      end.join(',')
      connection.should have_last_search_with(
        :"facet.query" => "{!ex=#{filter_tags}}category_ids_im:1"
      )
    end


    it 'ignores facet query with only empty rows' do
      search do
        facet :foo do
          row(:bar) {}
        end
      end
      connection.should_not have_last_search_with(:"facet.query")
    end

    it 'does not allow 0 arguments to facet method with block' do
      lambda do
        search do
          facet do
          end
        end
      end.should raise_error(ArgumentError)
    end

    it 'does not allow more than 1 argument to facet method with block' do
      lambda do
        search do
          facet :foo, :bar do
          end
        end
      end.should raise_error(ArgumentError)
    end
  end
end
