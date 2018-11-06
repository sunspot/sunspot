require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('../lib/sunspot/rails/spec_helper', File.dirname(__FILE__))

describe 'specs with Sunspot stubbed' do
  disconnect_sunspot

  before :each do
    @session = Sunspot.session.original_session
    @post = Post.create!
  end

  it 'should batch' do
    foo = double('Foo')
    block = lambda { foo.bar }

    expect(foo).to receive(:bar)

    Sunspot.batch(&block)
  end

  it 'should not send index to session' do
    expect(@session).not_to receive(:index)
    @post.index
  end

  it 'should not send index! to session' do
    expect(@session).not_to receive(:index!)
    @post.index!
  end

  it 'should not send atomic_update to session' do
    expect(@session).not_to receive(:atomic_update)
    @post.index
  end

  it 'should not send atomic_update! to session' do
    expect(@session).not_to receive(:atomic_update!)
    @post.index!
  end

  it 'should not send commit to session' do
    expect(@session).not_to receive(:commit)
    Sunspot.commit
  end

  it 'should not send remove to session' do
    expect(@session).not_to receive(:remove)
    @post.remove_from_index
  end

  it 'should not send remove! to session' do
    expect(@session).not_to receive(:remove)
    @post.remove_from_index!
  end

  it 'should not send remove_by_id to session' do
    expect(@session).not_to receive(:remove_by_id)
    Sunspot.remove_by_id(Post, 1)
  end

  it 'should not send remove_by_id! to session' do
    expect(@session).not_to receive(:remove_by_id!)
    Sunspot.remove_by_id!(Post, 1)
  end

  it 'should not send remove_all to session' do
    expect(@session).not_to receive(:remove_all)
    Post.remove_all_from_index
  end

  it 'should not send remove_all! to session' do
    expect(@session).not_to receive(:remove_all!)
    Post.remove_all_from_index!
  end

  it 'should not send optimize to session' do
    expect(@session).not_to receive(:optimize)
    Sunspot.optimize
  end

  it 'should return false for dirty?' do
    expect(@session).not_to receive(:dirty?)
    expect(Sunspot.dirty?).to eq(false)
  end

  it 'should not send commit_if_dirty to session' do
    expect(@session).not_to receive(:commit_if_dirty)
    Sunspot.commit_if_dirty
  end

  it 'should return false for delete_dirty?' do
    expect(@session).not_to receive(:delete_dirty?)
    expect(Sunspot.delete_dirty?).to eq(false)
  end

  it 'should not send commit_if_delete_dirty to session' do
    expect(@session).not_to receive(:commit_if_delete_dirty)
    Sunspot.commit_if_delete_dirty
  end

  it 'should not execute a search when #search called' do
    expect(@session).not_to receive(:search)
    Post.search
  end

  it 'should not execute a search when #search called with parameters' do
    expect(@session).not_to receive(:search)
    Post.search(:include => :blog, :select => 'id, title')
  end

  it 'should return a new search' do
    expect(@session).not_to receive(:new_search)
    expect(Sunspot.new_search(Post)).to respond_to(:execute)
  end

  it 'should not send more_like_this to session' do
    expect(@session).not_to receive(:more_like_this)
    Sunspot.more_like_this(@post)
  end

  it 'should not raise error when reindexing scope' do
    expect{ Post.solr_index }.to_not raise_error
  end

  describe 'stub search' do
    before :each do
      @search = Post.search
    end

    it 'should return empty results' do
      expect(@search.results).to eq([])
    end

    it 'should return empty hits' do
      expect(@search.hits).to eq([])
    end

    it 'should return the same for raw_results as hits' do
      expect(@search.raw_results).to eq(@search.hits)
    end

    it 'should return zero total' do
      expect(@search.total).to eq(0)
    end

    it 'should return empty results for a given facet' do
      expect(@search.facet(:category_id).rows).to eq([])
    end

    it 'should return empty results for a given dynamic facet' do
      expect(@search.dynamic_facet(:custom).rows).to eq([])
    end

    it 'should return empty array if listing facets' do
      expect(@search.facets).to eq([])
    end

    describe '#data_accessor_for' do
      before do
        @accessor = @search.data_accessor_for(Post)
      end

      it 'should provide accessor for select' do
        expect(@accessor).to respond_to(:select, :select=)
      end

      it 'should provide accessor for include' do
        expect(@accessor).to respond_to(:include, :include=)
      end
    end

    describe '#stats' do
      before do
        @stats = @search.stats(:price)
      end

      it 'should response to all the available data methods' do
        expect(@stats).to respond_to(
          :min,
          :max,
          :count,
          :sum,
          :missing,
          :sum_of_squares,
          :mean,
          :standard_deviation)
      end

      it 'should return empty results for a given facet' do
        expect(@stats.facet(:category_id).rows).to eq([])
      end

      it 'should return empty array if listing facets' do
        expect(@stats.facets).to eq([])
      end

    end
  end
end
