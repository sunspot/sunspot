require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'search stats' do
  before :each do
    Sunspot.remove_all
    @posts = Post.new(:ratings_average => 4.0, :author_name => 'plinio', :blog_id => 2),
             Post.new(:ratings_average => 4.0, :author_name => 'caio', :blog_id => 1),
             Post.new(:ratings_average => 3.0, :author_name => 'sempronio', :blog_id => 2)
    Sunspot.index!(@posts)
  end

  it 'returns minimum stats' do
    expect(Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).min).to eq(3.0)
  end

  it 'returns maximum stats' do
    expect(Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).max).to eq(4.0)
  end

  it 'returns count stats' do
    expect(Sunspot.search(Post) do
      stats :average_rating
    end.stats(:average_rating).count).to eq(3)
  end

  describe 'facets' do
    it 'returns minimum on facet row with two blog ids' do
      expect(Sunspot.search(Post) do
        stats :average_rating do
          facet :blog_id
        end
      end.stats(:average_rating).facet(:blog_id).rows[1].min).to eq(3.0)
    end

    it 'returns maximum on facet row with two blog ids' do
      expect(Sunspot.search(Post) do
        stats :average_rating do
          facet :blog_id
        end
      end.stats(:average_rating).facet(:blog_id).rows[1].max).to eq(4.0)
    end
  end

  describe 'json facets' do
    it 'returns minimum on facet row with two blog ids' do
      expect(Sunspot.search(Post) do
        stats :average_rating, sort: :min do
          json_facet :blog_id
        end
      end.json_facet_stats(:blog_id).rows[1].min).to eq(3.0)
    end

    it 'returns maximum on facet row with two blog ids' do
      expect(Sunspot.search(Post) do
        stats :average_rating, sort: :max do
          json_facet :blog_id
        end
      end.json_facet_stats(:blog_id).rows[1].max).to eq(4.0)
    end

    it 'returns only sum' do
      search = Sunspot.search(Post) do
        stats :average_rating, stats: [:sum] do
          json_facet :blog_id
        end
      end
      expect(search.json_facet_stats(:blog_id).rows[1].max).to eq(nil)
      expect(search.json_facet_stats(:blog_id).rows[1].min).to eq(nil)
      expect(search.json_facet_stats(:blog_id).rows[1].avg).to eq(nil)
      expect(search.json_facet_stats(:blog_id).rows[1].sumsq).to eq(nil)
      expect(search.json_facet_stats(:blog_id).rows[1].sum).to eq(4.0)
    end

    it 'works with nested facets' do
      search = Sunspot.search(Post) do
        stats :average_rating, sort: :min do
          json_facet(:blog_id, nested: { field: :author_name, limit: 3, nested: { field: :average_rating } } )
        end
      end
      expect(search.json_facet_stats(:blog_id).rows[1].nested.first.nested.first.min).to eq(4.0)
    end

  end
end
