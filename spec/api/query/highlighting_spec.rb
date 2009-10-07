require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'highlighted fulltext queries', :type => :query do
  it 'should not send highlight parameter when highlight not requested' do
    session.search(Post) do
      keywords 'test'
    end
    connection.should_not have_last_search_with(:hl)
  end

  it 'should enable highlighting when highlighting requested as keywords argument' do
    session.search(Post) do
      keywords 'test', :highlight => true
    end
    connection.should have_last_search_with(:hl => 'on')
  end

  it 'should not set highlight fields parameter if highlight fields are not passed' do
    session.search(Post) do
      keywords 'test', :highlight => true, :fields => [:title]
    end
    connection.should_not have_last_search_with(:'hl.fl')
  end

  it 'should enable highlighting on multiple fields when highlighting requested as array of fields via keywords argument' do
    session.search(Post) do
      keywords 'test', :highlight => [:title, :body]
    end

    connection.should have_last_search_with(:hl => 'on', :'hl.fl' => %w(title_text body_texts))
  end

  it 'should raise UnrecognizedFieldError if try to highlight unexisting field via keywords argument' do
    lambda {
      session.search(Post) do
        keywords 'test', :highlight => [:unknown_field]
      end
    }.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should enable highlighting on multiple fields when highlighting requested as list of fields via block call' do
    session.search(Post) do
      keywords 'test' do
        highlight :title, :body
      end
    end

    connection.should have_last_search_with(:hl => 'on', :'hl.fl' => %w(title_text body_texts))
  end

  it 'should raise UnrecognizedFieldError if try to highlight unexisting field via block call' do
    lambda {
      session.search(Post) do
        keywords 'test' do
          highlight :unknown_field
        end
      end
    }.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should set internal formatting' do
    session.search(Post) do
      keywords 'test', :highlight => true
    end
    connection.should have_last_search_with(
      :"hl.simple.pre" => '@@@hl@@@',
      :"hl.simple.post" => '@@@endhl@@@'
    )
  end

  it 'should set options and hihglight fields' do
    session.search(Post) do
      keywords 'test' do
        highlight :title, :max_snippets => 3
      end
    end
    connection.should have_last_search_with(
      :"hl.fl"       => %w(title_text),
      :"hl.snippets" => 3
    )
  end

  it 'should set maximum highlights per field' do
    session.search(Post) do
      keywords 'test' do
        highlight :max_snippets => 3
      end
    end
    connection.should have_last_search_with(
      :"hl.snippets" => 3
    )
  end

  it 'should set the maximum size' do
    session.search(Post) do
      keywords 'text' do
        highlight :fragment_size => 200
      end
    end
    connection.should have_last_search_with(
      :"hl.fragsize" => 200
    )
  end

  it 'enables merging of continuous fragments' do
    session.search(Post) do
      keywords 'test' do
        highlight :merge_continuous_fragments => true
      end
    end
    connection.should have_last_search_with(
      :"hl.mergeContinuous" => 'true'
    )
  end

  it 'enables use of phrase highlighter' do #TODO figure out what the hell this means
    session.search(Post) do
      keywords 'test' do
        highlight :phrase_highlighter => true
      end
    end
    connection.should have_last_search_with(
      :"hl.usePhraseHighlighter" => 'true'
    )
  end

  it 'requires field match if requested' do
    session.search(Post) do
      keywords 'test' do
        highlight :phrase_highlighter => true, :require_field_match => true
      end
    end
    connection.should have_last_search_with(
      :"hl.requireFieldMatch" => 'true'
    )
  end

end
