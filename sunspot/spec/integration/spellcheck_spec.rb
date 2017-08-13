require File.expand_path('../spec_helper', File.dirname(__FILE__))
include SearchHelper

describe 'spellcheck' do
  before :each do
    Sunspot.remove_all

    @posts = [
      Post.new(:title => 'Clojure Developer'),
      Post.new(:title => 'Conjure Flow'),
      Post.new(:title => 'Clojure Analyst'),
      Post.new(:title => 'C++ Developer'),
      Post.new(:title => 'C++ Developing')
    ]

    Sunspot.index!(*@posts)
    Sunspot.commit
  end

  it 'has no spellchecking by default' do
    search = Sunspot.search(Post) do
      keywords 'Closure'
    end
    expect(search.spellcheck_suggestions).to eq({})
  end

  it 'returns the list of suggestions' do
    search = Sunspot.search(Post) do
      keywords 'Closure'
      spellcheck :count => 3
    end
    expect(search.spellcheck_suggestions['closure']['suggestion']).to eq([
      {'word'=>'clojure', 'freq'=>2}, {'word'=>'conjure', 'freq'=>1}
    ])
  end

  it 'returns suggestion with highest frequency' do
    search = Sunspot.search(Post) do
      keywords 'Closure'
      spellcheck :count => 3
    end
    expect(search.spellcheck_suggestion_for('closure')).to eq('clojure')
  end

  it 'returns suggestion without collation when only more popular is true' do
    search = Sunspot.search(Post) do
      keywords 'Closure'
      spellcheck :count => 3, :only_more_popular => true, :collate => false
    end

    expect(search.spellcheck_suggestion_for('closure')).to eq('clojure')
  end

  context 'spellcheck collation' do
    it 'replaces terms that are not in the index if terms are provided' do

      search = Sunspot.search(Post) do
        keywords 'lojure developing'
        spellcheck :count => 3, :only_more_popular => true
      end
      expect(search.spellcheck_collation('lojure', 'developing')).to eq('clojure developing')
    end

    it 'returns Solr collation if terms are not provided' do

      search = Sunspot.search(Post) do
        keywords 'lojure developing'
        spellcheck :count => 3, :only_more_popular => true
      end
      expect(search.spellcheck_collation).to eq('clojure developer')
    end

    it 'returns Solr collation if terms are not provided even for single word' do

      search = Sunspot.search(Post) do
        keywords 'lojure'
        spellcheck :count => 3, :only_more_popular => true
      end
      expect(search.spellcheck_collation).to eq('clojure')
    end

    it 'returns Solr collation if terms are provided even for single word' do

      search = Sunspot.search(Post) do
        keywords 'lojure'
        spellcheck :count => 3
      end
      expect(search.spellcheck_collation).to eq('clojure')
    end

    it 'returns Solr collation if terms are provided even for single word' do

      search = Sunspot.search(Post) do
        keywords 'lojure'
        spellcheck :count => 3
      end
      expect(search.spellcheck_collation('lojure')).to eq('clojure')
    end

    it 'returns Solr collation if terms are provided even if single keyword is word' do

      search = Sunspot.search(Post) do
        keywords 'C++, lojure Developer'
        spellcheck :count => 3
      end
      expect(search.spellcheck_collation).to eq('C++, clojure Developer')
    end

    it 'returns nil if terms are provided which varies from actual keywords' do

      search = Sunspot.search(Post) do
        keywords 'clojure'
        spellcheck :count => 3
      end
      expect(search.spellcheck_collation('lojure')).to eq(nil)
    end
  end

end
