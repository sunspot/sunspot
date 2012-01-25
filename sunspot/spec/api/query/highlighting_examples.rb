shared_examples_for "query with highlighting support" do
  it 'should not send highlight parameter when highlight not requested' do
    search do
      keywords 'test'
    end
    connection.should_not have_last_search_with(:hl)
  end

  it 'should enable highlighting when highlighting requested as keywords argument' do
    search do
      keywords 'test', :highlight => true
    end
    connection.should have_last_search_with(:hl => 'on')
  end

  it 'should not set highlight fields parameter if highlight fields are not passed' do
    search do
      keywords 'test', :highlight => true, :fields => [:title]
    end
    connection.should_not have_last_search_with(:'hl.fl')
  end

  it 'should enable highlighting on multiple fields when highlighting requested as array of fields via keywords argument' do
    search do
      keywords 'test', :highlight => [:title, :body]
    end

    connection.should have_last_search_with(:hl => 'on', :'hl.fl' => %w(title_text body_textsv))
  end

  it 'should raise UnrecognizedFieldError if try to highlight unexisting field via keywords argument' do
    lambda {
      search do
        keywords 'test', :highlight => [:unknown_field]
      end
    }.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should enable highlighting on multiple fields when highlighting requested as list of fields via block call' do
    search do
      keywords 'test' do
        highlight :title, :body
      end
    end

    connection.should have_last_search_with(:hl => 'on', :'hl.fl' => %w(title_text body_textsv))
  end

  it 'should enable highlighting on multiple fields for multiple search types' do
    session.search(Post, Namespaced::Comment) do
      keywords 'test' do
        highlight :body
      end
    end
    connection.searches.last[:'hl.fl'].to_set.should == Set['body_text', 'body_textsv']
  end

  it 'should raise UnrecognizedFieldError if try to highlight unexisting field via block call' do
    lambda {
      search do
        keywords 'test' do
          highlight :unknown_field
        end
      end
    }.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should set internal formatting' do
    search do
      keywords 'test', :highlight => true
    end
    connection.should have_last_search_with(
      :"hl.simple.pre" => '@@@hl@@@',
      :"hl.simple.post" => '@@@endhl@@@'
    )
  end

  it 'should set highlight fields from DSL' do
    search do
      keywords 'test' do
        highlight :title
      end
    end
    connection.should have_last_search_with(
      :"hl.fl" => %w(title_text)
    )
  end

  it 'should not set formatting params specific to fields if fields specified' do
    search do
      keywords 'test', :highlight => :body
    end
    connection.should have_last_search_with(
      :"hl.simple.pre" => '@@@hl@@@',
      :"hl.simple.post" => '@@@endhl@@@'
    )
  end

  it 'should set maximum highlights per field' do
    search do
      keywords 'test' do
        highlight :max_snippets => 3
      end
    end
    connection.should have_last_search_with(
      :"hl.snippets" => 3
    )
  end

  it 'should set max snippets specific to highlight fields' do
    search do
      keywords 'test' do
        highlight :title, :max_snippets => 3
      end
    end
    connection.should have_last_search_with(
      :"hl.fl"       => %w(title_text),
      :"f.title_text.hl.snippets" => 3
    )
  end

  it 'should set the maximum size' do
    search do
      keywords 'text' do
        highlight :fragment_size => 200
      end
    end
    connection.should have_last_search_with(
      :"hl.fragsize" => 200
    )
  end

  it 'should set the maximum size for specific fields' do
    search do
      keywords 'text' do
        highlight :title, :fragment_size => 200
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.fragsize" => 200
    )
  end

  it 'enables merging of contiguous fragments' do
    search do
      keywords 'test' do
        highlight :merge_contiguous_fragments => true
      end
    end
    connection.should have_last_search_with(
      :"hl.mergeContiguous" => 'true'
    )
  end

  it 'enables merging of contiguous fragments for specific fields' do
    search do
      keywords 'test' do
        highlight :title, :merge_contiguous_fragments => true
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.mergeContiguous" => 'true'
    )
  end

  it 'enables use of phrase highlighter' do
    search do
      keywords 'test' do
        highlight :phrase_highlighter => true
      end
    end
    connection.should have_last_search_with(
      :"hl.usePhraseHighlighter" => 'true'
    )
  end

  it 'enables use of phrase highlighter for specific fields' do
    search do
      keywords 'test' do
        highlight :title, :phrase_highlighter => true
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.usePhraseHighlighter" => 'true'
    )
  end

  it 'requires field match if requested' do
    search do
      keywords 'test' do
        highlight :phrase_highlighter => true, :require_field_match => true
      end
    end
    connection.should have_last_search_with(
      :"hl.requireFieldMatch" => 'true'
    )
  end

  it 'requires field match for specified field if requested' do
    search do
      keywords 'test' do
        highlight :title, :phrase_highlighter => true, :require_field_match => true
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.requireFieldMatch" => 'true'
    )
  end

  it 'sets field specific params for different fields if different params given' do
    search do
      keywords 'test' do
        highlight :title, :max_snippets => 2
        highlight :body, :max_snippets => 1
      end
    end
    connection.should have_last_search_with(
      :"hl.fl" => %w(title_text body_textsv),
      :"f.title_text.hl.snippets" => 2,
      :"f.body_textsv.hl.snippets" => 1
    )
  end

  it 'sets the formatter for highlight output' do
    search do
      keywords 'test' do
        highlight :title, :formatter => 'formatter'
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.formatter" => 'formatter'
    )
  end

  it 'sets the text snippet generator for highlighted text' do
    search do
      keywords 'test' do
        highlight :title, :fragmenter => 'example_fragmenter'
      end
    end
    connection.should have_last_search_with(
      :"f.title_text.hl.fragmenter" => 'example_fragmenter'
    )
  end
end
