require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'fulltext query', :type => :query do
  it 'searches by keywords' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:q => 'keyword search')
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
    connection.should have_last_search_with(:fq => 'type:Post')
  end

  it 'searches all text fields for searched class' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_texts title_text)
  end

  it 'searches both stored and unstored text fields' do
    session.search Post, Namespaced::Comment do
      keywords 'keyword search'
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(author_name_text backwards_title_text body_text body_texts title_text)
  end

  it 'searches only specified text fields when specified' do
    session.search Post do
      keywords 'keyword search', :fields => [:title, :body]
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
        phrase_fields :title
      end
    end
    connection.should have_last_search_with(:pf => %w(title_text))
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
