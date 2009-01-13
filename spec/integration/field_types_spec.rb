require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'field types' do
  def self.test_field_type(name, field, *values)
    raise(ArgumentError, 'Please supply five values') unless values.length == 5

    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        @posts = values.map do |value|
          post = Post.new(field => value)
          Sunspot.index(post)
          post
        end
      end

      it 'should filter by exact match' do
        Sunspot.search(Post) { with.send(field, values[2]) }.results.should == [@posts[2]]
      end

      it 'should filter by less than' do
        results = Sunspot.search(Post) { with.send(field).less_than values[2] }.results
        (0..2).each { |i| results.should include(@posts[i]) }
        (3..4).each { |i| results.should_not include(@posts[i]) }
      end

      it 'should filter by greater than' do
        results = Sunspot.search(Post) { with.send(field).greater_than values[2] }.results
        (2..4).each { |i| results.should include(@posts[i]) }
        (0..1).each { |i| results.should_not include(@posts[i]) }
      end

      it 'should filter by between' do
        results = Sunspot.search(Post) { with.send(field).between(values[1]..values[3]) }.results
        (1..3).each { |i| results.should include(@posts[i]) }
        [0, 4].each { |i| results.should_not include(@posts[i]) }
      end

      it 'should filter by any of' do
        results = Sunspot.search(Post) { with.send(field).any_of(values.values_at(1, 3)) }.results
        [1, 3].each { |i| results.should include(@posts[i]) }
        [0, 2, 4].each { |i| results.should_not include(@posts[i]) }
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

  test_field_type 'String', :title, 'apple', 'banana', 'cherry', 'date', 'eggplant'
  test_field_type 'Integer', :blog_id, -2, 0, 3, 12, 20
  test_field_type 'Float', :average_rating, -2.5, 0.0, 3.2, 3.5, 16.0
  test_field_type 'Time', :published_at, *(['1970-01-01 00:00:00 UTC', '1983-07-08 04:00:00 UTC', '1983-07-08 02:00:00 -0500',
                                            '2005-11-05 10:00:00 UTC', Time.now.to_s].map { |t| Time.parse(t) })
end
