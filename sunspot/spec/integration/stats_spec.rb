require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'search stats' do
  before :each do
    Sunspot.remove_all
    @posts = Post.new(:ratings_average => 4.0, :blog_id => 2),
             Post.new(:ratings_average => 4.0, :blog_id => 1),
             Post.new(:ratings_average => 3.0, :blog_id => 2)
    Sunspot.index!(@posts)
  end

  it 'returns minimum stats' do
    Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).min.should == 3.0
  end

  it 'returns maximum stats' do
    Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).max.should == 4.0
  end

  it 'returns count stats' do
    Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).count.should == 3
  end

  describe 'facets' do
    it 'returns minimum on facet row with two blog ids' do
      Sunspot.search(Post) do
        stats :average_rating do
          facet :blog_id
        end
      end.stats(:average_rating).facet(:blog_id).rows[1].min.should == 3.0
    end

    it 'returns maximum on facet row with two blog ids' do
      Sunspot.search(Post) do
        stats :average_rating do
          facet :blog_id
        end
      end.stats(:average_rating).facet(:blog_id).rows[1].max.should == 4.0
    end
  end
end
