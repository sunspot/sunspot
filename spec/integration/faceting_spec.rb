require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'search faceting' do
  def self.test_field_type(name, attribute, field, value1, value2)
    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        2.times do
          Sunspot.index(Post.new(attribute => value1))
        end
        Sunspot.index(Post.new(attribute => value2))
        Sunspot.commit
      end

      before :each do
        @search = Sunspot.search(Post) do
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
  test_field_type('Boolean', :featured, :featured, true, false)

  context 'facet options' do
    before :all do
      Sunspot.remove_all
      facet_values = %w(zero one two three four)
      facet_values.each_with_index do |value, i|
        i.times { Sunspot.index(Post.new(:title => value, :blog_id => 1)) }
      end
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
  end
end
