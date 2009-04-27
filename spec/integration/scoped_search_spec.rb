require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'scoped_search' do
  def self.test_field_type(name, attribute, field, *values)
    raise(ArgumentError, 'Please supply five values') unless values.length == 5

    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        @posts = values.map do |value|
          post = Post.new(attribute => value)
          Sunspot.index(post)
          post
        end
        Sunspot.commit
      end

      it 'should filter by exact match' do
        Sunspot.search(Post) { with.send(field, values[2]) }.results.should == [@posts[2]]
      end

      it 'should reject by inexact match' do
        results = Sunspot.search(Post) { without.send(field, values[2]) }.results
        [0, 1, 3, 4].each { |i| results.should include(@posts[i]) }
        results.should_not include(@posts[2])
      end

      it 'should filter by less than' do
        results = Sunspot.search(Post) { with.send(field).less_than values[2] }.results
        (0..2).each { |i| results.should include(@posts[i]) }
        (3..4).each { |i| results.should_not include(@posts[i]) }
      end

      it 'should reject by less than' do
        results = Sunspot.search(Post) { without.send(field).less_than values[2] }.results
        (0..2).each { |i| results.should_not include(@posts[i]) }
        (3..4).each { |i| results.should include(@posts[i]) }
      end

      it 'should filter by greater than' do
        results = Sunspot.search(Post) { with.send(field).greater_than values[2] }.results
        (2..4).each { |i| results.should include(@posts[i]) }
        (0..1).each { |i| results.should_not include(@posts[i]) }
      end

      it 'should reject by greater than' do
        results = Sunspot.search(Post) { without.send(field).greater_than values[2] }.results
        (2..4).each { |i| results.should_not include(@posts[i]) }
        (0..1).each { |i| results.should include(@posts[i]) }
      end

      it 'should filter by between' do
        results = Sunspot.search(Post) { with.send(field).between(values[1]..values[3]) }.results
        (1..3).each { |i| results.should include(@posts[i]) }
        [0, 4].each { |i| results.should_not include(@posts[i]) }
      end

      it 'should reject by between' do
        results = Sunspot.search(Post) { without.send(field).between(values[1]..values[3]) }.results
        (1..3).each { |i| results.should_not include(@posts[i]) }
        [0, 4].each { |i| results.should include(@posts[i]) }
      end

      it 'should filter by any of' do
        results = Sunspot.search(Post) { with.send(field).any_of(values.values_at(1, 3)) }.results
        [1, 3].each { |i| results.should include(@posts[i]) }
        [0, 2, 4].each { |i| results.should_not include(@posts[i]) }
      end

      it 'should reject by any of' do
        results = Sunspot.search(Post) { without.send(field).any_of(values.values_at(1, 3)) }.results
        [1, 3].each { |i| results.should_not include(@posts[i]) }
        [0, 2, 4].each { |i| results.should include(@posts[i]) }
      end

      it 'should order by field ascending' do
        results = Sunspot.search(Post) { order_by field, :asc }.results
        results.should == @posts
      end

      it 'should order by field descending' do
        results = Sunspot.search(Post) { order_by field, :desc }.results
        results.should == @posts.reverse
      end
    end
  end

  test_field_type 'String', :title, :title, 'apple', 'banana', 'cherry', 'date', 'eggplant'
  test_field_type 'Integer', :blog_id, :blog_id, -2, 0, 3, 12, 20
  test_field_type 'Float', :ratings_average, :average_rating, -2.5, 0.0, 3.2, 3.5, 16.0
  test_field_type 'Time', :published_at, :published_at, *(['1970-01-01 00:00:00 UTC', '1983-07-08 04:00:00 UTC', '1983-07-08 02:00:00 -0500',
                                                           '2005-11-05 10:00:00 UTC', Time.now.to_s].map { |t| Time.parse(t) })

  describe 'Boolean field type' do
    before :all do
      Sunspot.remove_all
      @posts = [Post.new(:featured => true), Post.new(:featured => false)].each { |post| Sunspot.index(post) }
      Sunspot.commit
    end

    it 'should filter by exact match' do
      Sunspot.search(Post) { with.featured true }.results.should == [@posts[0]]
    end
  end

  describe 'exclusion by identity' do
    before do
      @posts = (1..5).map do |i|
        post = Post.new
        Sunspot.index(post)
        post
      end
      Sunspot.commit
    end

    it 'should not return excluded object' do
      excluded_post = @posts.shift
      Sunspot.search(Post) { without(excluded_post) }.results.should_not include(excluded_post)
    end

    it 'should return objects not excluded' do
      excluded_post = @posts.shift
      for included_post in @posts
        Sunspot.search(Post) { without(excluded_post) }.results.should include(included_post)
      end
    end

    it 'should not return excluded objects' do
      excluded_posts = [@posts.shift, @posts.shift]
      for excluded_post in excluded_posts
        Sunspot.search(Post) { without(excluded_posts) }.results.should_not include(excluded_post)
      end
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
      search.results.should == @posts
    end
  end
end
