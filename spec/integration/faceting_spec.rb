describe 'search faceting' do
  def self.test_field_type(name, field, value1, value2)
    context "with field of type #{name}" do
      before :all do
        Sunspot.remove_all
        2.times do
          Sunspot.index(Post.new(field => value1))
        end
        Sunspot.index(Post.new(field => value2))
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

  test_field_type('String', :title, 'Title 1', 'Title 2')
  test_field_type('Integer', :blog_id, 3, 4)
  test_field_type('Float', :average_rating, 2.2, 1.1)
  test_field_type('Time', :published_at, Time.mktime(2008, 02, 17, 17, 45, 04),
                                         Time.mktime(2008, 07, 02, 03, 56, 22))
end
