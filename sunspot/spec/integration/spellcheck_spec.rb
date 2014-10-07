require File.expand_path('../spec_helper', File.dirname(__FILE__))
include SearchHelper

describe 'spellcheck' do
  before :each do
    Sunspot.remove_all

    @posts = [
      Post.new(:title => 'Java Developer'),
      Post.new(:title => 'Lava Flow'),
      Post.new(:title => 'Java Analyst'),
      Post.new(:title => 'C++ Developer'),
      Post.new(:title => 'C++ Developing')
    ]

    Sunspot.index!(*@posts)
    Sunspot.commit
  end

  it 'returns the list of suggestions' do
    search = Sunspot.search(Post) do
      keywords 'Wava'
      spellcheck :count => 3
    end

    search.spellcheck_suggestions['Wava']['suggestion'].should ==  [{'word'=>'java', 'freq'=>2}, {'word'=>'lava', 'freq'=>1}]
  end

  it 'returns suggestion with highest frequency' do
    search = Sunspot.search(Post) do
      keywords 'Wava'
      spellcheck :count => 3
    end

    search.spellcheck_suggestion_for('Wava').should == 'java'
  end

  context 'spellcheck collation' do

    it 'replaces terms that are not in the index if terms are provided' do

      search = Sunspot.search(Post) do
        keywords 'wava developing'
        spellcheck :count => 3, :only_more_popular => true
      end
      search.spellcheck_collation('wava', 'developing').should == 'java developing'
    end

    it 'returns Solr collation if terms are not provided' do

      search = Sunspot.search(Post) do
        keywords 'wava developing'
        spellcheck :count => 3, :only_more_popular => true
      end
      search.spellcheck_collation.should == 'java developer'
    end
  end

end
