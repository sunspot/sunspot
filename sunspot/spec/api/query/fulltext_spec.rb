require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'fulltext query', :type => :query do
  it 'searches by keywords' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:q => 'keyword search')
  end

  it 'ignores keywords if empty' do
    session.search Post do
      keywords ''
    end
    connection.should_not have_last_search_with(:defType => 'dismax')
  end

  it 'ignores keywords if nil' do
    session.search Post do
      keywords nil
    end
    connection.should_not have_last_search_with(:defType => 'dismax')
  end

  it 'ignores keywords with only whitespace' do
    session.search Post do
      keywords "  \t"
    end
    connection.should_not have_last_search_with(:defType => 'dismax')
  end

  it 'gracefully ignores keywords block if keywords ignored' do
    session.search Post do
      keywords(nil) { fields(:title) }
    end
  end

  it 'sets default query parser to dismax when keywords used' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:defType => 'dismax')
  end

  it 'searches types in filter query if keywords used' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:fq => ['type:Post'])
  end

  it 'searches all text fields for searched class' do
    search = session.search Post do
      keywords 'keyword search'
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_mlt_textv body_texts title_text)
  end

  it 'searches both stored and unstored text fields' do
    session.search Post, Namespaced::Comment do
      keywords 'keyword search'
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(author_name_text backwards_title_text body_mlt_textv body_text body_texts title_text)
  end

  it 'searches only specified text fields when specified' do
    session.search Post do
      keywords 'keyword search', :fields => [:title, :body]
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_texts title_text)
  end

  it 'excludes text fields when instructed' do
    session.search Post do
      keywords 'keyword search' do
        exclude_fields :backwards_title, :body_mlt
      end
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_texts title_text)
  end

  it 'assigns boost to fields when specified' do
    session.search Post do
      keywords 'keyword search' do
        fields :title => 2.0, :body => 0.75
      end
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_texts^0.75 title_text^2.0)
  end

  it 'allows assignment of boosted and unboosted fields' do
    session.search Post do
      keywords 'keyword search' do
        fields :body, :title => 2.0
      end
    end
  end

  it 'searches both unstored and stored text field with same name when specified' do
    session.search Post, Namespaced::Comment do
      keywords 'keyword search', :fields => [:body]
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_text body_texts)
  end

  it 'requests score when keywords used' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:fl => '* score')
  end

  it 'does not request score when keywords not used' do
    session.search Post
    connection.should_not have_last_search_with(:fl)
  end

  it 'sets phrase fields' do
    session.search Post do
      keywords 'great pizza' do
        phrase_fields :title => 2.0
      end
    end
    connection.should have_last_search_with(:pf => 'title_text^2.0')
  end

  it 'sets phrase fields with boost' do
    session.search Post do
      keywords 'great pizza' do
        phrase_fields :title => 1.5
      end
    end
    connection.should have_last_search_with(:pf => 'title_text^1.5')
  end

  it 'sets phrase slop from DSL' do
    session.search Post do
      keywords 'great pizza' do
        phrase_slop 2
      end
    end
    connection.should have_last_search_with(:ps => 2)
  end

  it 'sets boost for certain fields without restricting fields' do
    session.search Post do
      keywords 'great pizza' do
        boost_fields :title => 1.5
      end
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_mlt_textv body_texts title_text^1.5)
  end

  it 'ignores boost fields that do not apply' do
    session.search Post do
      keywords 'great pizza' do
        boost_fields :bogus => 1.2, :title => 1.5
      end
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_mlt_textv body_texts title_text^1.5)
  end

  it 'sets default boost with default fields' do
    session.search Photo do
      keywords 'great pizza'
    end
    connection.should have_last_search_with(:qf => 'caption_text^1.5')
  end

  it 'sets default boost with fields specified in options' do
    session.search Photo do
      keywords 'great pizza', :fields => [:caption]
    end
    connection.should have_last_search_with(:qf => 'caption_text^1.5')
  end

  it 'sets default boost with fields specified in DSL' do
    session.search Photo do
      keywords 'great pizza' do
        fields :caption
      end
    end
    connection.should have_last_search_with(:qf => 'caption_text^1.5')
  end

  it 'overrides default boost when specified in DSL' do
    session.search Photo do
      keywords 'great pizza' do
        fields :caption => 2.0
      end
    end
    connection.should have_last_search_with(:qf => 'caption_text^2.0')
  end

  it 'creates boost query' do
    session.search Post do
      keywords 'great pizza' do
        boost 2.0 do
          with(:average_rating).greater_than(2.0)
        end
      end
    end
    connection.should have_last_search_with(:bq => ['average_rating_f:[2\.0 TO *]^2.0'])
  end

  it 'creates multiple boost queries' do
    session.search Post do
      keywords 'great pizza' do
        boost(2.0) do
          with(:average_rating).greater_than(2.0)
        end
        boost(1.5) do
          with(:featured, true)
        end
      end
    end
    connection.should have_last_search_with(
      :bq => [
        'average_rating_f:[2\.0 TO *]^2.0',
        'featured_b:true^1.5'
      ]
    )
  end

  it 'sends minimum match parameter from options' do
    session.search Post do
      keywords 'great pizza', :minimum_match => 2
    end
    connection.should have_last_search_with(:mm => 2)
  end

  it 'sends minimum match parameter from DSL' do
    session.search Post do
      keywords('great pizza') { minimum_match(2) }
    end
    connection.should have_last_search_with(:mm => 2)
  end

  it 'sends tiebreaker parameter from options' do
    session.search Post do
      keywords 'great pizza', :tie => 0.1
    end
    connection.should have_last_search_with(:tie => 0.1)
  end

  it 'sends tiebreaker parameter from DSL' do
    session.search Post do
      keywords('great pizza') { tie(0.1) }
    end
    connection.should have_last_search_with(:tie => 0.1)
  end

  it 'sends query phrase slop from options' do
    session.search Post do
      keywords 'great pizza', :query_phrase_slop => 2
    end
    connection.should have_last_search_with(:qs => 2)
  end

  it 'sends query phrase slop from DSL' do
    session.search Post do
      keywords('great pizza') { query_phrase_slop(2) }
    end
    connection.should have_last_search_with(:qs => 2)
  end

  it 'allows specification of a text field that only exists in one type' do
    session.search Post, Namespaced::Comment do
      keywords 'keywords', :fields => :author_name
    end
    connection.searches.last[:qf].should == 'author_name_text'
  end

  it 'raises Sunspot::UnrecognizedFieldError for nonexistant fields in keywords' do
    lambda do
      session.search Post do
        keywords :text, :fields => :bogus
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end
end
