require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'faceting', :type => :search do
  it 'returns field name for facet' do
    stub_facet(:title_ss, {})
    result = session.search Post do
      facet :title
    end
    result.facet(:title).field_name.should == :title
  end

  it 'returns facet specified by string' do
    stub_facet(:title_ss, {})
    result = session.search Post do
      facet :title
    end
    result.facet('title').field_name.should == :title
  end

  it 'returns all facets specified by search' do
    stub_facet(:title_ss, { 'Author 1' => 1 })
    stub_facet(:blog_id_i, { '1' => 3 })
    result = session.search(Post) do
      facet :title
      facet :blog_id
    end
    result.facets.first.field_name.should == :title
    result.facets.last.field_name.should == :blog_id
  end

  it 'returns string facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_values(result, :title).should == ['Author 1', 'Author 2']
  end

  it 'returns counts for facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_counts(result, :title).should == [2, 1]
  end

  it 'returns integer facet' do
    stub_facet(:blog_id_i, '3' => 2, '1' => 1)
    result = session.search Post do
      facet :blog_id
    end
    facet_values(result, :blog_id).should == [3, 1]
  end

  it 'returns float facet' do
    stub_facet(:average_rating_ft, '9.3' => 2, '1.1' => 1)
    result = session.search Post do
      facet :average_rating
    end
    facet_values(result, :average_rating).should == [9.3, 1.1]
  end

  it 'returns time facet' do
    stub_facet(
      :published_at_dt,
      '2009-04-07T20:25:23Z' => 3,
      '2009-04-07T20:26:19Z' => 2,
      '2050-04-07T20:27:15Z' => 1
    )
    result = session.search Post do
      facet :published_at
    end
    # In JRuby, Time doesn't have 32-bit range constraint, apparently.
    future_time =
      begin
        Time.gm(2050, 4, 7, 20, 27, 15)
      rescue ArgumentError
        DateTime.civil(2050, 4, 7, 20, 27, 15)
      end
    facet_values(result, :published_at).should ==
      [Time.gm(2009, 4, 7, 20, 25, 23),
       Time.gm(2009, 4, 7, 20, 26, 19),
       future_time]
  end

  it 'returns date facet' do
    stub_facet(
      :expire_date_d,
      '2009-07-13T00:00:00Z' => 3,
      '2009-04-01T00:00:00Z' => 1
    )
    result = session.search(Post) do
      facet :expire_date
    end
    facet_values(result, :expire_date).should ==
      [Date.new(2009, 07, 13),
       Date.new(2009, 04, 01)]
  end

  it 'returns trie integer facet' do
    stub_facet(:size_it, '3' => 2, '1' => 1)
    result = session.search Photo do
      facet :size
    end
    facet_values(result, :size).should == [3, 1]
  end

  it 'returns float facet' do
    stub_facet(:average_rating_ft, '9.3' => 2, '1.1' => 1)
    result = session.search Photo do
      facet :average_rating
    end
    facet_values(result, :average_rating).should == [9.3, 1.1]
  end

  it 'returns time facet' do
    stub_facet(
      :created_at_dt,
      '2009-04-07T20:25:23Z' => 3,
      '2009-04-07T20:26:19Z' => 1
    )
    result = session.search Photo do
      facet :created_at
    end
    facet_values(result, :created_at).should ==
      [Time.gm(2009, 04, 07, 20, 25, 23),
       Time.gm(2009, 04, 07, 20, 26, 19)]
  end

  it 'returns boolean facet' do
    stub_facet(:featured_bs, 'true' => 3, 'false' => 1)
    result = session.search(Post) { facet(:featured) }
    facet_values(result, :featured).should == [true, false]
  end


  { 'string' => 'blog', 'symbol' => :blog }.each_pair do |type, name|
    it "returns field facet with #{type} custom name" do
      stub_facet(:blog, '2' => 1, '1' => 4)
      result = session.search(Post) { facet(:blog_id, :name => name) }
      facet_values(result, :blog).should == [1, 2]
    end

    it "assigns #{type} custom name to field facet" do
      stub_facet(:blog, '2' => 1)
      result = session.search(Post) { facet(:blog_id, :name => name) }
      result.facet(:blog).name.should == :blog
    end

    it "retains field name for #{type} custom-named field facet" do
      stub_facet(:blog, '2' => 1)
      result = session.search(Post) { facet(:blog_id, :name => name) }
      result.facet(:blog).field_name.should == :blog_id
    end
  end

  it 'returns class facet' do
    stub_facet(:class_name, 'Post' => 3, 'Namespaced::Comment' => 1)
    result = session.search(Post) { facet(:class) }
    facet_values(result, :class).should == [Post, Namespaced::Comment]
  end

  it 'returns special :any facet' do
    stub_query_facet(
      'category_ids_im:[* TO *]' => 3
    )
    search = session.search(Post) { facet(:category_ids, :extra => :any) }
    row = search.facet(:category_ids).rows.first
    row.value.should == :any
    row.count.should == 3
  end

  it 'returns special :none facet' do
    stub_query_facet(
      '-category_ids_im:[* TO *]' => 3
    )
    search = session.search(Post) { facet(:category_ids, :extra => :none) }
    row = search.facet(:category_ids).rows.first
    row.value.should == :none
    row.count.should == 3
  end

  it 'returns date range facet' do
    stub_date_facet(:published_at_dt, 60*60*24, '2009-07-08T04:00:00Z' => 2, '2009-07-07T04:00:00Z' => 1)
    start_time = Time.utc(2009, 7, 7, 4)
    end_time = start_time + 2*24*60*60
    result = session.search(Post) { facet(:published_at, :time_range => start_time..end_time) }
    facet = result.facet(:published_at)
    facet.rows.first.value.should == (start_time..(start_time+24*60*60))
    facet.rows.last.value.should == ((start_time+24*60*60)..end_time)
  end

  it 'returns date range facet sorted by count' do
    stub_date_facet(:published_at_dt, 60*60*24, '2009-07-08T04:00:00Z' => 2, '2009-07-07T04:00:00Z' => 1)
    start_time = Time.utc(2009, 7, 7, 4)
    end_time = start_time + 2*24*60*60
    result = session.search(Post) { facet(:published_at, :time_range => start_time..end_time, :sort => :count) }
    facet = result.facet(:published_at)
    facet.rows.first.value.should == ((start_time+24*60*60)..end_time)
    facet.rows.last.value.should == (start_time..(start_time+24*60*60))
  end

  it 'returns query facet' do
    stub_query_facet(
      'average_rating_ft:[3\.0 TO 5\.0]' => 3,
      'average_rating_ft:[1\.0 TO 3\.0]' => 1
    )
    search = session.search(Post) do
      facet :average_rating do
        row 3.0..5.0 do
          with :average_rating, 3.0..5.0
        end
        row 1.0..3.0 do
          with :average_rating, 1.0..3.0
        end
      end
    end
    facet = search.facet(:average_rating)
    facet.rows.first.value.should == (3.0..5.0)
    facet.rows.first.count.should == 3
    facet.rows.last.value.should == (1.0..3.0)
    facet.rows.last.count.should == 1
  end

  describe 'query facet option handling' do
    def facet_values_from_options(options = {})
      session.search(Post) do
        facet :average_rating, options do
          row(1) { with(:average_rating, 1.0..2.0) }
          row(3) { with(:average_rating, 3.0..4.0) }
          row(2) { with(:average_rating, 2.0..3.0) }
          row(4) { with(:average_rating, 4.0..5.0) }
        end
      end.facet(:average_rating).rows.map { |row| row.value }
    end

    before :each do
      stub_query_facet(
        'average_rating_ft:[1\.0 TO 2\.0]' => 2,
        'average_rating_ft:[2\.0 TO 3\.0]' => 3,
        'average_rating_ft:[3\.0 TO 4\.0]' => 1,
        'average_rating_ft:[4\.0 TO 5\.0]' => 0
      )
    end

    it 'sorts in order of specification if no limit is given' do
      facet_values_from_options.should == [1, 3, 2]
    end

    it 'sorts lexically if lexical option is specified' do
      facet_values_from_options(:sort => :index).should == [1, 2, 3]
    end

    it 'sorts by count by default if limit is given' do
      facet_values_from_options(:limit => 2).should == [2, 1]
    end

    it 'sorts by count if count option is specified' do
      facet_values_from_options(:sort => :count).should == [2, 1, 3]
    end

    it 'sorts lexically if lexical option is specified even if limit is given' do
      facet_values_from_options(:sort => :index, :limit => 2).should == [1, 2]
    end

    it 'limits facets if limit option is given' do
      facet_values_from_options(:limit => 1).should == [2]
    end

    it 'does not limit facets if limit option is negative' do
      facet_values_from_options(:limit => -2).should == [1, 3, 2]
    end

    it 'returns all facets if limit greater than number of facets' do
      facet_values_from_options(:limit => 10).should == [2, 1, 3]
    end

    it 'allows zero count if specified' do
      facet_values_from_options(:zeros => true).should == [1, 3, 2, 4]
    end

    it 'sets minimum count' do
      facet_values_from_options(:minimum_count => 2).should == [1, 2]
    end
  end

  it 'returns limited field facet' do
    stub_query_facet(
      'category_ids_im:1' => 3,
      'category_ids_im:3' => 1
    )
    search = session.search(Post) do
      facet :category_ids, :only => [1, 3, 5]
    end
    facet = search.facet(:category_ids)
    facet.rows.first.value.should == 1
    facet.rows.first.count.should == 3
    facet.rows.last.value.should == 3
    facet.rows.last.count.should == 1
  end

  it 'returns instantiated facet values' do
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    search = session.search(Post) { facet(:blog_id) }
    search.facet(:blog_id).rows.map { |row| row.instance }.should == blogs
  end

  it 'returns all instantiated facet rows, whether or not the instances exist' do
    blogs = Array.new(2) { Blog.new }
    blogs.last.destroy
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    search = session.search(Post) { facet(:blog_id) }
    search.facet(:blog_id).rows.map { |row| row.instance }.should == [blogs.first, nil]
  end

  it 'returns only rows with available instances if specified' do
    blogs = Array.new(2) { Blog.new }
    blogs.last.destroy
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    search = session.search(Post) { facet(:blog_id) }
    search.facet(:blog_id).rows(:verify => true).map { |row| row.instance }.should == blogs[0..0]
  end

  it 'returns both verified and unverified rows from the same facet' do
    blogs = Array.new(2) { Blog.new }
    blogs.last.destroy
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    search = session.search(Post) { facet(:blog_id) }
    search.facet(:blog_id).rows(:verify => true).map { |row| row.instance }.should == blogs[0..0]
    search.facet(:blog_id).rows.map { |row| row.instance }.should == [blogs.first, nil]
  end

  it 'ignores :verify option if facet not a reference facet' do
    stub_facet(:category_ids_im, '1' => 2, '2' => 1)
    search = session.search(Post) { facet(:category_ids) }
    search.facet(:category_ids).should have(2).rows(:verify => true)
  end

  it 'returns instantiated facet values for limited field facet' do
    blogs = Array.new(2) { Blog.new }
    stub_query_facet(
      "blog_id_i:#{blogs[0].id}" => 3,
      "blog_id_i:#{blogs[1].id}" => 1
    )
    search = session.search(Post) do
      facet(:blog_id, :only => blogs.map { |blog| blog.id })
    end
    search.facet(:blog_id).rows.map { |row| row.instance }.should == blogs
  end

  it 'only queries the persistent store once for an instantiated facet' do
    query_count = Blog.query_count
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    result = session.search(Post) { facet(:blog_id) }
    result.facet(:blog_id).rows.each { |row| row.instance }
    (Blog.query_count - query_count).should == 1
  end
end
