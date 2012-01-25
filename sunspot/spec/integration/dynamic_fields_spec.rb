require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'dynamic fields' do
  before :each do
    Sunspot.remove_all
    @posts = Post.new(:custom_string => { :cuisine => 'Pizza' }),
             Post.new(:custom_string => { :cuisine => 'Greek' }),
             Post.new(:custom_string => { :cuisine => 'Greek' })
    Sunspot.index!(@posts)
  end

  it 'should search for dynamic string field' do
    Sunspot.search(Post) do
      dynamic(:custom_string) do
        with(:cuisine, 'Pizza')
      end
    end.results.should == [@posts.first]
  end

  describe 'faceting' do
    before :each do
      @search = Sunspot.search(Post) do
        dynamic :custom_string do
          facet :cuisine
        end
      end
    end

    it 'should return value "value" with count 2' do
      row = @search.dynamic_facet(:custom_string, :cuisine).rows[0]
      row.value.should == 'Greek'
      row.count.should == 2
    end

    it 'should return value "other" with count 1' do
      row = @search.dynamic_facet(:custom_string, :cuisine).rows[1]
      row.value.should == 'Pizza'
      row.count.should == 1
    end
  end

  it 'should order by dynamic string field ascending' do
    Sunspot.search(Post) do
      dynamic :custom_string do
        order_by :cuisine, :asc
      end
    end.results.last.should == @posts.first
  end

  it 'should order by dynamic string field descending' do
    Sunspot.search(Post) do
      dynamic :custom_string do
        order_by :cuisine, :desc
      end
    end.results.first.should == @posts.first
  end
end
