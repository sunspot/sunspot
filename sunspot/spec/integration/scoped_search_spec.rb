require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'scoped_search' do
  def self.test_field_type(name, attribute, field, *values)
    clazz =
      if values.first.is_a?(Class)
        values.shift
      else
        Post
      end
    raise(ArgumentError, 'Please supply five values') unless values.length == 5

    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        @objects = values.map do |value|
          object = clazz.new(attribute => value)
          Sunspot.index(object)
          object
        end
        Sunspot.commit
      end

      it 'should filter by exact match' do
        expect(Sunspot.search(clazz) { with(field, values[2]) }.results).to eq([@objects[2]])
      end

      it 'should reject by inexact match' do
        results = Sunspot.search(clazz) { without(field, values[2]) }.results
        [0, 1, 3, 4].each { |i| expect(results).to include(@objects[i]) }
        expect(results).not_to include(@objects[2])
      end

      it 'should filter by less than' do
        results = Sunspot.search(clazz) { with(field).less_than values[2] }.results
        (0..1).each { |i| expect(results).to include(@objects[i]) }
        (2..4).each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by less than' do
        results = Sunspot.search(clazz) { without(field).less_than values[2] }.results
        (0..1).each { |i| expect(results).not_to include(@objects[i]) }
        (2..4).each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should filter by less than or equal to' do
        results = Sunspot.search(clazz) { with(field).less_than_or_equal_to values[2] }.results
        (0..2).each { |i| expect(results).to include(@objects[i]) }
        (3..4).each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by less than or equal to' do
        results = Sunspot.search(clazz) { without(field).less_than_or_equal_to values[2] }.results
        (0..2).each { |i| expect(results).not_to include(@objects[i]) }
        (3..4).each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should filter by greater than' do
        results = Sunspot.search(clazz) { with(field).greater_than values[2] }.results
        (3..4).each { |i| expect(results).to include(@objects[i]) }
        (0..2).each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by greater than' do
        results = Sunspot.search(clazz) { without(field).greater_than values[2] }.results
        (3..4).each { |i| expect(results).not_to include(@objects[i]) }
        (0..2).each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should filter by greater than or equal to' do
        results = Sunspot.search(clazz) { with(field).greater_than_or_equal_to values[2] }.results
        (2..4).each { |i| expect(results).to include(@objects[i]) }
        (0..1).each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by greater than' do
        results = Sunspot.search(clazz) { without(field).greater_than_or_equal_to values[2] }.results
        (2..4).each { |i| expect(results).not_to include(@objects[i]) }
        (0..1).each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should filter by between' do
        results = Sunspot.search(clazz) { with(field).between(values[1]..values[3]) }.results
        (1..3).each { |i| expect(results).to include(@objects[i]) }
        [0, 4].each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by between' do
        results = Sunspot.search(clazz) { without(field).between(values[1]..values[3]) }.results
        (1..3).each { |i| expect(results).not_to include(@objects[i]) }
        [0, 4].each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should filter by any of' do
        results = Sunspot.search(clazz) { with(field).any_of(values.values_at(1, 3)) }.results
        [1, 3].each { |i| expect(results).to include(@objects[i]) }
        [0, 2, 4].each { |i| expect(results).not_to include(@objects[i]) }
      end

      it 'should reject by any of' do
        results = Sunspot.search(clazz) { without(field).any_of(values.values_at(1, 3)) }.results
        [1, 3].each { |i| expect(results).not_to include(@objects[i]) }
        [0, 2, 4].each { |i| expect(results).to include(@objects[i]) }
      end

      it 'should order by field ascending' do
        results = Sunspot.search(clazz) { order_by field, :asc }.results
        expect(results).to eq(@objects)
      end

      it 'should order by field descending' do
        results = Sunspot.search(clazz) { order_by field, :desc }.results
        expect(results).to eq(@objects.reverse)
      end
    end
  end

  test_field_type 'String', :title, :title, 'apple pie', 'banana split', 'cherry tart', 'date pastry', 'eggplant a la mode'
  test_field_type 'Integer', :blog_id, :blog_id, -2, 0, 3, 12, 20
  test_field_type 'Long', :hash, :hash, Namespaced::Comment, 2**29, 2**30, 2**31, 2**32, 2**33
  test_field_type 'Float', :ratings_average, :average_rating, -2.5, 0.0, 3.2, 3.5, 16.0
  test_field_type 'Double', :average_rating, :average_rating, Namespaced::Comment, -2.5, 0.0, 3.2, 3.5, 16.0
  test_field_type 'Time', :published_at, :published_at, *(['1970-01-01 00:00:00 UTC', '1983-07-08 04:00:00 UTC', '1983-07-08 02:00:00 -0500',
                                                           '2005-11-05 10:00:00 UTC', Time.now.to_s].map { |t| Time.parse(t) })
  test_field_type 'Trie Integer', :size, :size, Photo, -2, 0, 3, 12, 20
  test_field_type 'Trie Float', :average_rating, :average_rating, Photo, -2.5, 0.0, 3.2, 3.5, 16.0
  test_field_type 'Trie Time', :created_at, :created_at, Photo, *(['1970-01-01 00:00:00 UTC', '1983-07-08 04:00:00 UTC', '1983-07-08 02:00:00 -0500',
                                                                   '2005-11-05 10:00:00 UTC', Time.now.to_s].map { |t| Time.parse(t) })
  describe 'Date range field type' do
    let(:date_ranges) do
      {
        'December and January' => Date.new(2014,12,25)..Date.new(2015,1,10),
        'January only' => Date.new(2015,1,5)..Date.new(2015,1,20),
        'January and February' => Date.new(2015,1,25)..Date.new(2015,2,10),
        'February only' => Date.new(2015,2,5)..Date.new(2015,2,20),
        'December to February' => Date.new(2014,12,25)..Date.new(2015,2,10),
        'January to March' => Date.new(2015,1,25)..Date.new(2015,3,10),
        'December to March' => Date.new(2014,12,25)..Date.new(2015,3,20)
      }
    end

    before :all do
      january = Date.new(2015,1,1)..Date.new(2015,1,31)
      february = Date.new(2015,2,1)..Date.new(2015,2,28)
      Sunspot.remove_all
      @posts = [Post.new(featured_for: january), Post.new(featured_for: february), Post.new]
      Sunspot.index!(@posts)
    end

    it 'should filter by Contains' do
      expect(featured_for_posts(:containing, Date.new(2015,1,15) )).to eq([@posts[0]])
      expect(featured_for_posts(:containing, 'December and January')).to be_empty
      expect(featured_for_posts(:containing, 'January only')).to eq([@posts[0]])
      expect(featured_for_posts(:containing, 'January only', negated = true)).to eq(@posts[1..-1])
    end

    it 'should filter by Intersects' do
      expect(featured_for_posts(:intersecting, Date.new(2015,1,15) )).to eq([@posts[0]])
      expect(featured_for_posts(:intersecting, 'January only')).to eq([@posts[0]])
      expect(featured_for_posts(:intersecting, 'January and February')).to eq(@posts[0..1])
      expect(featured_for_posts(:intersecting, 'January and February', negated = true)).to eq([@posts[2]])
      expect(featured_for_posts(:intersecting, 'February only')).to eq([@posts[1]])
      expect(featured_for_posts(:intersecting, 'February only', negated = true)).to eq([@posts[0], @posts[2]])
    end

    it 'should filter by Within' do
      expect(featured_for_posts(:within, Date.new(2015,1,15) )).to be_empty
      (date_ranges.keys - date_ranges.keys.grep(/ to /)).each do |key|
        expect(featured_for_posts(:within, key)).to be_empty
      end
      expect(featured_for_posts(:within, 'December to February')).to eq([@posts[0]])
      expect(featured_for_posts(:within, 'December to February', negated = true)).to eq(@posts[1..-1])
      expect(featured_for_posts(:within, 'January to March')).to eq([@posts[1]])
      expect(featured_for_posts(:within, 'January to March', negated = true)).to eq([@posts[0], @posts[2]])
      expect(featured_for_posts(:within, 'December to March')).to eq(@posts[0..1])
      expect(featured_for_posts(:within, 'December to March', negated = true)).to eq([@posts[2]])
    end
  end

  describe 'Boolean field type' do
    before :all do
      Sunspot.remove_all
      @posts = [Post.new(:featured => true), Post.new(:featured => false), Post.new]
      Sunspot.index!(@posts)
    end

    it 'should filter by exact match for true' do
      expect(Sunspot.search(Post) { with(:featured, true) }.results).to eq([@posts[0]])
    end

    it 'should filter for exact match for false' do
      expect(Sunspot.search(Post) { with(:featured, false) }.results).to eq([@posts[1]])
    end
  end

  describe 'Legacy (static) fields' do
    it "allows for using symbols in defining static field names" do
      Sunspot.remove_all
      Sunspot.index!(legacy = Post.new(:title => "foo"))
      expect(Sunspot.search(Post) { with(:legacy, "legacy foo") }.results).to eq([legacy])
    end
  end

  describe 'reserved words' do
    %w(AND OR NOT TO).each do |word|
      it "should successfully search for #{word.inspect}" do
        Sunspot.index!(post = Post.new(:title => word))
        expect(Sunspot.search(Post) { with(:title, word) }.results).to eq([post])
      end
    end
  end

  describe 'passing nil value to equal' do
    before :all do
      Sunspot.remove_all
      @posts = [Post.new(:title => 'apple'), Post.new]
      Sunspot.index!(@posts)
    end

    it 'should filter results without value for field' do
      expect(Sunspot.search(Post) { with(:title, nil) }.results).to eq([@posts[1]])
    end

    it 'should exclude results without value for field' do
      expect(Sunspot.search(Post) { without(:title, nil) }.results).to eq([@posts[0]])
    end
  end

  describe 'prefix searching' do
    before :each do
      Sunspot.remove_all
      @posts = ['test', 'test post', 'some test', 'bogus'].map do |title|
        Post.new(:title => title)
      end
      Sunspot.index!(@posts)
    end

    it 'should return results whose prefix matches' do
      expect(Sunspot.search(Post) { with(:title).starting_with('test') }.results).to eq(@posts[0..1])
    end
  end

  describe 'inclusion by identity' do
    before do
      Sunspot.remove_all
      @posts = (1..5).map do |i|
        post = Post.new
        Sunspot.index(post)
        post
      end
      Sunspot.commit
    end

    it 'should only return included object' do
      included_post = @posts.shift
      expect(Sunspot.search(Post) { with(included_post) }.results).to include(included_post)
    end

    it 'should not return objects not included' do
      included_post = @posts.shift
      for excluded_post in @posts
        expect(Sunspot.search(Post) { with(included_post) }.results).not_to include(excluded_post)
      end
    end

    it 'should return included objects' do
      included_posts = [@posts.shift, @posts.shift]
      for included_post in included_posts
        expect(Sunspot.search(Post) { with(included_posts) }.results).to include(included_post)
      end
    end
  end

  describe 'exclusion by identity' do
    before do
      Sunspot.remove_all
      @posts = (1..5).map do |i|
        post = Post.new
        Sunspot.index(post)
        post
      end
      Sunspot.commit
    end

    it 'should not return excluded object' do
      excluded_post = @posts.shift
      expect(Sunspot.search(Post) { without(excluded_post) }.results).not_to include(excluded_post)
    end

    it 'should return objects not excluded' do
      excluded_post = @posts.shift
      for included_post in @posts
        expect(Sunspot.search(Post) { without(excluded_post) }.results).to include(included_post)
      end
    end

    it 'should not return excluded objects' do
      excluded_posts = [@posts.shift, @posts.shift]
      for excluded_post in excluded_posts
        expect(Sunspot.search(Post) { without(excluded_posts) }.results).not_to include(excluded_post)
      end
    end
  end

  describe 'connectives' do
    before :each do
      Sunspot.remove_all
    end

    it 'should return results that match any restriction in a disjunction' do
      posts = (1..3).map { |i| Post.new(:blog_id => i)}
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        any_of do
          with(:blog_id, 1)
          with(:blog_id, 2)
        end
      end.results).to eq(posts[0..1])
    end

    it 'should return results, ignoring any restriction in a disjunction that has been passed an empty array' do
      posts = (1..3).map { |i| Post.new(:blog_id => i)}
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        with(:blog_id, [])
      end.results).to eq(posts)
    end

    it 'should return results, ignoring any restriction in a negative disjunction that has been passed an empty array' do
      posts = (1..3).map { |i| Post.new(:blog_id => i)}
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        without(:blog_id, [])
      end.results).to eq(posts)
    end

    it 'should return results, ignoring any restriction in a conjunction that has been passed an empty array' do
      posts = (1..3).map { |i| Post.new(:blog_id => i)}
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        all_of do
          with(:blog_id, 1)
          with(:blog_id, [])
        end
      end.results).to eq(posts[0..0])
    end

    it 'should return results, ignoring any restriction in a negative conjunction that has been passed an empty array' do
      posts = (1..3).map { |i| Post.new(:blog_id => i)}
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        all_of do
          with(:blog_id, 1)
          without(:blog_id, [])
        end
      end.results).to eq(posts[0..0])
    end

    it 'should return results that match a nested conjunction in a disjunction' do
      posts = [
        Post.new(:title => 'No', :blog_id => 1),
        Post.new(:title => 'Yes', :blog_id => 2),
        Post.new(:title => 'Yes', :blog_id => 3),
        Post.new(:title => 'No', :blog_id => 2)
      ]
      Sunspot.index!(posts)
      expect(Sunspot.search(Post) do
        any_of do
          with(:blog_id, 1)
          all_of do
            with(:blog_id, 2)
            with(:title, 'Yes')
          end
        end
      end.results).to eq(posts[0..1])
    end

    it 'should return results that match a conjunction with a negated restriction' do
      posts = [
        Post.new(:title => 'No', :blog_id => 1),
        Post.new(:title => 'Yes', :blog_id => 2),
        Post.new(:title => 'No', :blog_id => 2)
      ]
      Sunspot.index!(posts)
      search = Sunspot.search(Post) do
        any_of do
          with(:blog_id, 1)
          without(:title, 'No')
        end
      end
      expect(search.results).to eq(posts[0..1])
    end

    it 'should return results that match a conjunction with a disjunction with a conjunction with a negated restriction' do
      posts = [
        Post.new(:title => 'Yes', :ratings_average => 2.0),
        Post.new(:blog_id => 1, :category_ids => [4], :ratings_average => 2.0),
        Post.new(:blog_id => 1),
        Post.new(:blog_id => 2),
        Post.new(:blog_id => 1, :ratings_average => 2.0)
      ]
      Sunspot.index!(posts)
      search = Sunspot.search(Post) do
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
      expect(search.results).to eq(posts[0..2])
    end

    it 'should return results that match a disjunction with a negated restriction and a nested disjunction in a conjunction with a negated restriction' do
      posts = [
        Post.new,
        Post.new(:title => 'Yes', :blog_id => 1, :category_ids => [4], :ratings_average => 2.0),
        Post.new(:title => 'Yes', :blog_id => 1),
        Post.new(:title => 'Yes'),
        Post.new(:title => 'Yes', :category_ids => [4], :ratings_average => 2.0),
        Post.new(:title => 'Yes', :blog_id => 1, :ratings_average => 2.0)
      ]
      Sunspot.index!(posts)
      search = Sunspot.search(Post) do
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
      expect(search.results).to eq(posts[0..2])
    end
  end

  describe 'multiple column ordering' do
    before do
      Sunspot.remove_all
      @posts = [
        Post.new(:ratings_average => 2, :title => 'banana'),
        Post.new(:ratings_average => 2, :title => 'eggplant'),
        Post.new(:ratings_average => 1, :title => 'apple')
      ].each { |post| Sunspot.index(post) }
      Sunspot.commit
    end

    it 'should order with precedence given' do
      search = Sunspot.search(Post) do
        order_by :average_rating, :desc
        order_by :sort_title, :asc
      end
      expect(search.results).to eq(@posts)
    end
  end

  describe 'ordering by random' do
    before do
      Sunspot.remove_all
      Sunspot.index!(Array.new(100) { Post.new })
    end

    def search_ordered_by_random(direction = nil)
      Sunspot.search(Post) do
        order_by(:random, direction)
        paginate(:page => 1, :per_page => 100)
      end
    end

    it 'should order randomly' do
      result_sets = Array.new(5) do
        search_ordered_by_random.results.map { |result| result.id }
      end
      expect(result_sets.uniq.size).to be > 1
    end

    it 'should order randomly using the order_by function and passing a direction' do
      result_sets = Array.new(5) do
        search_ordered_by_random(:desc).results.map { |result| result.id }
      end
      expect(result_sets.uniq.size).to be > 1
    end

    context 'when providing a custom seed value' do
      before do
        @first_results = search_ordered_by_random(:seed => 12345).results.map { |result| result.id }
      end

      it 'should return different results when passing a different seed value' do
        next_results = search_ordered_by_random(:seed => 54321).results.map { |result| result.id }
        expect(next_results).not_to eq(@first_results)
      end

      it 'should return the same results when passing the same seed value' do
        next_results = search_ordered_by_random(:seed => 12345).results.map { |result| result.id }
        expect(next_results).to eq(@first_results)
      end
    end
  end

  describe 'ordering by function' do
    before :all do
      Sunspot.remove_all
      @p1 = Post.new(:blog_id => 1, :category_ids => [3])
      @p2 = Post.new(:blog_id => 2, :category_ids => [1])
      Sunspot.index([@p1,@p2])
      Sunspot.commit
    end

    it 'should order by sum' do
      # 1+3 > 2+1
      search = Sunspot.search(Post) {order_by_function :sum, :blog_id, :primary_category_id, :desc}
      expect(search.results.first).to eq(@p1)
    end

    it 'should order by product and sum' do
      # 1 * (1+3) < 2 * (2+1)
      search = Sunspot.search(Post) { order_by_function :product, :blog_id, [:sum,:blog_id,:primary_category_id], :desc}
      expect(search.results.first).to eq(@p2)
    end

    it 'should accept string literals' do
      # (1 * -2) > (2 * -2)
      search = Sunspot.search(Post) {order_by_function :product, :blog_id, '-2', :desc}
      expect(search.results.first).to eq(@p1)
    end

    it 'should accept non-string literals' do
      # (1 * -2) > (2 * -2)
      search = Sunspot.search(Post) {order_by_function :product, :blog_id, -2, :desc}
      expect(search.results.first).to eq(@p1)
    end
  end
end
