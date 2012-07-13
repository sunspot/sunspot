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
        row.value.should == value1
        row.count.should == 2
      end

      it "should return value #{value2.inspect} with count 1" do
        row = @search.facet(field).rows[1]
        row.value.should == value2
        row.count.should == 1
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
      search.facet(:title).should have(3).rows
    end

    it 'should not return zeros by default' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title
      end
      search.facet(:title).rows.map { |row| row.value }.should_not include('zero')
    end

    it 'should return zeros when specified' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :zeros => true
      end
      search.facet(:title).rows.map { |row| row.value }.should include('zero')
    end
    
    it 'should return facet rows from an offset' do
      search = Sunspot.search(Post) do
        facet :title, :offset => 3
      end
      search.facet(:title).rows.map { |row| row.value }.should == %w(one zero)
    end

    it 'should return a specified minimum count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :minimum_count => 2
      end
      search.facet(:title).rows.map { |row| row.value }.should == %w(four three two)
    end

    it 'should order facets lexically' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :sort => :index
      end
      search.facet(:title).rows.map { |row| row.value }.should == %w(four one three two)
    end

    it 'should order facets by count' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :sort => :count
      end
      search.facet(:title).rows.map { |row| row.value }.should == %w(four three two one)
    end

    it 'should limit facet values by prefix' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :prefix => 't'
      end
      search.facet(:title).rows.map { |row| row.value }.sort.should == %w(three two)
    end

    it 'should return :all facet' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :extra => :any
      end
      search.facet(:title).rows.first.value.should == :any
      search.facet(:title).rows.first.count.should == 10
    end

    it 'should return :none facet' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :extra => :none
      end
      search.facet(:title).rows.first.value.should == :none
      search.facet(:title).rows.first.count.should == 1
    end

    it 'gives correct facet count when group == true and truncate == true' do
      search = Sunspot.search(Post) do
        group :title do
          truncate
        end

        facet :title, :extra => :any
      end

      # Should be 5 instead of 11
      search.facet(:title).rows.first.count.should == 5
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
      search.facet(:title).rows.map { |row| row.value }.sort.should == ["title with spaces 1", "title with spaces 2"]
    end

    it 'should limit facet values by a prefix with slashes' do
      search = Sunspot.search(Post) do
        with :blog_id, 1
        facet :title, :prefix => 'title/'
      end
      search.facet(:title).rows.map { |row| row.value }.sort.should == ["title/with/slashes/1", "title/with/slashes/2"]
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
        search.facet(:category_ids).rows.map { |row| row.value }.to_set.should == Set[1, 2]
      end

      it 'should use facet keys to facet more than once with different exclusions' do
        search = Sunspot.search(Post) do
          with(:blog_id, 1)
          category_filter = with(:category_ids, 1)
          facet(:category_ids)
          facet(:category_ids, :exclude => category_filter, :name => :all_category_ids)
        end
        search.facet(:category_ids).rows.map { |row| row.value }.should == [1]
        search.facet(:all_category_ids).rows.map { |row| row.value }.to_set.should == Set[1, 2]
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
        search.facet(:category_ids).rows.map { |row| [row.value, row.count] }.to_set.should == Set[[:category_1, 1], [:category_2, 1]]
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
        search.facet(:category_ids).rows.map { |row| [row.value, row.count] }.to_set.should == Set[[:category_1, 1]]
        search.facet(:all_category_ids).rows.map { |row| [row.value, row.count] }.to_set.should == Set[[:category_1, 1], [:category_2, 1]]
      end
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
      search.facet(:published_at).rows.first.value.should == (time..(time + 60*60*24))
      search.facet(:published_at).rows.first.count.should == 2
      search.facet(:published_at).rows.last.value.should == ((time + 60*60*24)..(time + 60*60*24*2))
      search.facet(:published_at).rows.last.count.should == 1
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
      search.facet(:class).rows.first.value.should == Post
      search.facet(:class).rows.first.count.should == 2
      search.facet(:class).rows.last.value.should == Namespaced::Comment
      search.facet(:class).rows.last.count.should == 1
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
      facet.rows[0].value.should == (3.0..4.0)
      facet.rows[0].count.should == 3
      facet.rows[1].value.should == (1.0..2.0)
      facet.rows[1].count.should == 2
      facet.rows[2].value.should == (4.0..5.0)
      facet.rows[2].count.should == 1
    end
  end
end
