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
    connection.searches.last[:qf].split(' ').sort.should == %w(backwards_title_text body_text title_text)
  end

  it 'searches only specified text fields when specified' do
    session.search Post do
      keywords 'keyword search', :fields => [:title, :body]
    end
    connection.searches.last[:qf].split(' ').sort.should == %w(body_text title_text)
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

  it 'searches all text fields for all types under search' do
    session.search Post, Namespaced::Comment do
      keywords 'keywords'
    end
    connection.searches.last[:qf].split(' ').sort.should == 
      %w(author_name_text backwards_title_text body_text title_text)
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
