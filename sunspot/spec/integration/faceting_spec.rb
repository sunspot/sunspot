require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'search faceting' do
  def self.test_field_type(name, attribute, field, *args)
    clazz, value1, value2 =
      if args.length == 2
        [Post, args.first, args.last]
      else
        args
      end

    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        2.times do
          Sunspot.index(clazz.new(attribute => value1))
        end
        Sunspot.index(clazz.new(attribute => value2))
        Sunspot.commit
      end

      before :each do
        @search = Sunspot.search(clazz) do
          facet(field)
        end
      end

      it "should return value #{value1.inspect} with count 2" do
        row = @search.facet(field).rows[0]
        expect(row.value).to eq(value1)
        expect(row.count).to eq(2)
      end

      it "should return value #{value2.inspect} with count 1" do
        row = @search.facet(field).rows[1]
        expect(row.value).to eq(value2)
        expect(row.count).to eq(1)
      end
    end
  end

  test_field_type('String', :title, :title, 'Title 1', 'Title 2')
  test_field_type('Integer', :blog_id, :blog_id, 3, 4)
  test_field_type('Float', :ratings_average, :average_rating, 2.2, 1.1)
  test_field_type('Time', :published_at, :published_at, Time.mktime(2008, 02, 17, 17, 45, 04),
                                                        Time.mktime(2008, 07, 02, 03, 56, 22))
  test_field_type('Trie Integer', :size, :size, Photo, 3, 4)
  test_field_type('Float', :average_rating, :average_rating, Photo, 2.2, 1.1)
  test_field_type('Time', :created_at, :created_at, Photo, Time.mktime(2008, 02, 17, 17, 45, 04),
                                                           Time.mktime(2008, 07, 02, 03, 56, 22))
  test_field_type('Boolean', :featured, :featured, true, false)

  context 'facet options' do
    before :all do
      Sunspot.remove_all
      facet_values = %w(zero one two three four)
      facet_values.each_with_index do |value, i|
        i.times { Sunspot.index(Post.new(:title => value, :blog_id => 1)) }
      end
      Sunspot.index(Post.new(:blog_id => 1))
      Sunspot.index(Post.new(:title => 'zero', :blog_id => 2))
      Sunspot.commit
    end

    it 'should limit the number of facet rows' do
      search = Sunspot.search(Post) do
        facet :title, :limit => 3
      end
      expect(search.facet(:title).rows.size).to eq(3)
    end

    it 'should not return zeros by default' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title
      end
      expect(search.facet(:title).rows.map { |row| row.value }).not_to include('zero')
    end

    it 'should return zeros when specified' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :zeros => true
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to include('zero')
    end
    
    it 'should return facet rows from an offset' do
      search = Sunspot.search(Post) do
        facet :title, :offset => 3
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(one zero))
    end

    it 'should return a specified minimum count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :minimum_count => 2
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four three two))
    end

    it 'should order facets lexically' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :sort => :index
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four one three two))
    end

    it 'should order facets by count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :sort => :count
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four three two one))
    end

    it 'should limit facet values by prefix' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :prefix => 't'
      end
      expect(search.facet(:title).rows.map { |row| row.value }.sort).to eq(%w(three two))
    end

    it 'should return :all facet' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :extra => :any
      end
      expect(search.facet(:title).rows.first.value).to eq(:any)
      expect(search.facet(:title).rows.first.count).to eq(10)
    end

    it 'should return :none facet' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :extra => :none
      end
      expect(search.facet(:title).rows.first.value).to eq(:none)
      expect(search.facet(:title).rows.first.count).to eq(1)
    end

    it 'gives correct facet count when group == true and truncate == true' do
      search = Sunspot.search(Post) do
        group :title do
          truncate
        end

        facet :title, :extra => :any
      end

      # Should be 5 instead of 11
      expect(search.facet(:title).rows.first.count).to eq(5)
    end
  end

  context 'json facet options' do
    before :all do
      Sunspot.remove_all
      facet_values = %w(zero one two three four)
      facet_values.each_with_index do |value, i|
        i.times { Sunspot.index(Post.new(:title => value, :blog_id => 1)) }
      end
      Sunspot.index(Post.new(:blog_id => 1))
      Sunspot.index(Post.new(:title => 'zero', :blog_id => 2))
      Sunspot.commit
    end

    it 'should return indexed elements' do
      search = Sunspot.search(Post) do
         json_facet(:title)
      end
      expect(search.facet(:title).rows.size).to eq(5)
    end

    it 'should limit the number of facet rows' do
      search = Sunspot.search(Post) do
        json_facet :title, :limit => 3
      end
      expect(search.facet(:title).rows.size).to eq(3)
    end

    it 'should not return zeros by default' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        json_facet :title
      end
      expect(search.facet(:title).rows.map { |row| row.value }).not_to include('zero')
    end

    it 'should return a specified minimum count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        json_facet :title, :minimum_count => 2
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four three two))
    end

    it 'should order facets lexically' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        json_facet :title, :sort => :index
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four one three two))
    end

    it 'should order facets by count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        json_facet :title, :sort => :count
      end
      expect(search.facet(:title).rows.map { |row| row.value }).to eq(%w(four three two one))
    end

    it 'should limit facet values by prefix' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        json_facet :title, :prefix => 't'
      end
      expect(search.facet(:title).rows.map { |row| row.value }.sort).to eq(%w(three two))
    end

  end

  context 'nested json facet' do
    before :all do
      Sunspot.remove_all
      facet_values = %w(zero one two three four)
      nested_facet_values = %w(alfa bravo charlie delta)

      facet_values.each do |value|
        nested_facet_values.each do |v2|
          Sunspot.index(Post.new(:title => value, :author_name => v2, :blog_id => 1))
        end
      end

      0.upto(9) { |i| Sunspot.index(Post.new(:title => 'zero', :author_name => "another#{i}", :blog_id => 1)) }
      
      Sunspot.commit
    end

    it 'should get nested' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name } )
      end
      expect(search.facet(:title).rows.first.nested.size).to eq(4)
    end

    it 'without limit take the first 10' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name } )
      end
      expect(search.facet(:title).rows.last.nested.size).to eq(10)
    end

    it 'without limit' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name, limit: -1 } )
      end
      expect(search.facet(:title).rows.last.nested.size).to eq(14)
    end

    it 'works with distinct' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name, distinct: { strategy: :unique } } )
      end
      expect(search.facet(:title).rows.first.nested.map(&:count).uniq.size).to eq(1)
    end

    it 'should limit the nested facet' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name, limit: 2 } )
      end
      expect(search.facet(:title).rows.first.nested.size).to eq(2)
    end

    it 'should work nested of nested' do
      search = Sunspot.search(Post) do
        json_facet(:title, nested: { field: :author_name, nested: { field: :title } } )
      end
      expect(search.facet(:title).rows.first.nested.first.nested.size).to eq(1)
      expect(search.facet(:title).rows.first.nested.first.nested.first.nested).to eq(nil)
    end

  end

  context 'prefix escaping' do
    before do
      Sunspot.remove_all
      ["title1", "title2", "title with spaces 1", "title with spaces 2", "title/with/slashes/1", "title/with/slashes/2"].each do |value|
        Sunspot.index(Post.new(:title => value, :blog_id => 1))
      end
      Sunspot.commit
    end

    it 'should limit facet values by a prefix with spaces' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :prefix => 'title '
      end
      expect(search.facet(:title).rows.map { |row| row.value }.sort).to eq(["title with spaces 1", "title with spaces 2"])
    end

    it 'should limit facet values by a prefix with slashes' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :prefix => 'title/'
      end
      expect(search.facet(:title).rows.map { |row| row.value }.sort).to eq(["title/with/slashes/1", "title/with/slashes/2"])
    end
  end

  context 'multiselect faceting' do
    before do
      Sunspot.remove_all
      Sunspot.index!(
        Post.new(:blog_id => 1, :category_ids => [1]),
        Post.new(:blog_id => 1, :category_ids => [2]),
        Post.new(:blog_id => 3, :category_ids => [3])
      )
    end

    context 'field faceting' do
      it 'should exclude filter from faceting' do
        search = Sunspot.search(Post) do
          with(:blog_id, 1)
          category_filter = with(:category_ids, 1)
          facet(:category_ids, :exclude => category_filter)
        end
        expect(search.facet(:category_ids).rows.map { |row| row.value }.to_set).to eq(Set[1, 2])
      end

      it 'should use facet keys to facet more than once with different exclusions' do
        search = Sunspot.search(Post) do
          with(:blog_id, 1)
          category_filter = with(:category_ids, 1)
          facet(:category_ids)
          facet(:category_ids, :exclude => category_filter, :name => :all_category_ids)
        end
        expect(search.facet(:category_ids).rows.map { |row| row.value }).to eq([1])
        expect(search.facet(:all_category_ids).rows.map { |row| row.value }.to_set).to eq(Set[1, 2])
      end
    end

    context 'query faceting' do
      it 'should exclude filter from faceting' do
        search = Sunspot.search(Post) do
          with(:blog_id, 1)
          category_filter = with(:category_ids, 1)
          facet :category_ids, :exclude => category_filter do
            row(:category_1) do
              with(:category_ids, 1)
            end
            row(:category_2) do
              with(:category_ids, 2)
            end
          end
        end
        expect(search.facet(:category_ids).rows.map { |row| [row.value, row.count] }.to_set).to eq(Set[[:category_1, 1], [:category_2, 1]])
      end

      it 'should use facet keys to facet more than once with different exclusions' do
        search = Sunspot.search(Post) do
          with(:blog_id, 1)
          category_filter = with(:category_ids, 1)
          facet :category_ids do
            row(:category_1) do
              with(:category_ids, 1)
            end
            row(:category_2) do
              with(:category_ids, 2)
            end
          end

          facet :all_category_ids, :exclude => category_filter do
            row(:category_1) do
              with(:category_ids, 1)
            end
            row(:category_2) do
              with(:category_ids, 2)
            end
          end
        end
        expect(search.facet(:category_ids).rows.map { |row| [row.value, row.count] }.to_set).to eq(Set[[:category_1, 1]])
        expect(search.facet(:all_category_ids).rows.map { |row| [row.value, row.count] }.to_set).to eq(Set[[:category_1, 1], [:category_2, 1]])
      end
    end
  end

  context 'distinct field facets' do
    before :all do
      Sunspot.remove_all

      Sunspot.index!(
          (0..5).map { |i| Post.new(:blog_id => i, :title => 'title') }
      )

      0.upto(3) { |i| Sunspot.index(Post.new(:blog_id => i, :title => 'title')) }

      Sunspot.index!(Post.new(:blog_id => 4, :title => 'other title'))
      Sunspot.index!(Post.new(:blog_id => 5, :title => 'other title'))

      Sunspot.index!(Post.new(:blog_id => 40, :title => 'title'))
      Sunspot.index!(Post.new(:blog_id => 40, :title => 'title'))

      Sunspot.index!(Post.new(:blog_id => 40, :title => 'other title'))
      Sunspot.index!(Post.new(:blog_id => 40, :title => 'other title'))
    end

    it 'should return unique indexed elements for a field' do
      search = Sunspot.search(Post) do
        json_facet(:blog_id, distinct: { strategy: :unique })
      end

      expect(search.facet(:blog_id).rows.size).to eq(7)
      expect(search.facet(:blog_id).rows.map(&:count).uniq.size).to eq(1)
    end

    it 'should return unique indexed elements for a field and facet on a field' do
      search = Sunspot.search(Post) do
        json_facet(:blog_id, distinct: { group_by: :title, strategy: :unique })
      end

      expect(search.facet(:blog_id).rows.size).to eq(2)
      expect(search.facet(:blog_id).rows[0].count).to eq(3)
      expect(search.facet(:blog_id).rows[1].count).to eq(7)
    end

    it 'should return unique indexed elements for a field and facet on a field with hll' do
      search = Sunspot.search(Post) do
        json_facet(:blog_id, distinct: { group_by: :title, strategy: :hll })
      end

      expect(search.facet(:blog_id).rows.size).to eq(2)
      expect(search.facet(:blog_id).rows[0].count).to eq(3)
      expect(search.facet(:blog_id).rows[1].count).to eq(7)
    end

  end

  context 'date facets' do
    before :all do
      Sunspot.remove_all
      time = Time.utc(2009, 7, 8)
      Sunspot.index!(
        (0..2).map { |i| Post.new(:published_at => time + i*60*60*16) }
      )
    end

    it 'should return time ranges' do
      time = Time.utc(2009, 7, 8)
      search = Sunspot.search(Post) do
        facet :published_at, :time_range => time..(time + 60*60*24*2), :sort => :count
      end
      expect(search.facet(:published_at).rows.first.value).to eq(time..(time + 60*60*24))
      expect(search.facet(:published_at).rows.first.count).to eq(2)
      expect(search.facet(:published_at).rows.last.value).to eq((time + 60*60*24)..(time + 60*60*24*2))
      expect(search.facet(:published_at).rows.last.count).to eq(1)
    end

    it 'json facet should return time ranges' do
      days_diff = 15
      time_from = Time.utc(2009, 7, 8)
      time_to = Time.utc(2009, 7, 8 + days_diff)
      search = Sunspot.search(Post) do
        json_facet(
            :published_at,
            :time_range => time_from..time_to
        )
      end

      expect(search.facet(:published_at).rows.size).to eq(days_diff)
      expect(search.facet(:published_at).rows[0].count).to eq(2)
      expect(search.facet(:published_at).rows[1].count).to eq(1)
    end

    it 'json facet should return time ranges with custom gap' do
      days_diff = 10
      time_from = Time.utc(2009, 7, 8)
      time_to = Time.utc(2009, 7, 8 + days_diff)
      search = Sunspot.search(Post) do
        json_facet(
            :published_at,
            :time_range => time_from..time_to,
            gap: 60*60*24*2
        )
      end
      expect(search.facet(:published_at).rows.size).to eq(days_diff / 2)
      expect(search.facet(:published_at).rows[0].count).to eq(3)
    end

  end

  context 'class facets' do
    before :all do
      Sunspot.remove_all
      Sunspot.index!(Post.new, Post.new, Namespaced::Comment.new)
    end

    it 'should return classes' do
      search = Sunspot.search(Post, Namespaced::Comment) do
        facet(:class, :sort => :count)
      end
      expect(search.facet(:class).rows.first.value).to eq(Post)
      expect(search.facet(:class).rows.first.count).to eq(2)
      expect(search.facet(:class).rows.last.value).to eq(Namespaced::Comment)
      expect(search.facet(:class).rows.last.count).to eq(1)
    end
  end

  context 'query facets' do
    before :all do
      Sunspot.remove_all
      Sunspot.index!(
        [1.1, 1.2, 3.2, 3.4, 3.9, 4.1].map do |rating|
          Post.new(:ratings_average => rating)
        end
      )
    end

    it 'should return specified facets' do
      search = Sunspot.search(Post) do
        facet :rating_range, :sort => :count do
          for rating in [1.0, 2.0, 3.0, 4.0]
            range = rating..(rating + 1.0)
            row range do
              with :average_rating, rating..(rating + 1.0)
            end
          end
        end
      end
      facet = search.facet(:rating_range)
      expect(facet.rows[0].value).to eq(3.0..4.0)
      expect(facet.rows[0].count).to eq(3)
      expect(facet.rows[1].value).to eq(1.0..2.0)
      expect(facet.rows[1].count).to eq(2)
      expect(facet.rows[2].value).to eq(4.0..5.0)
      expect(facet.rows[2].count).to eq(1)
    end
  end
end
