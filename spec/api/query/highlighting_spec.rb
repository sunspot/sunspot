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

  it 'should set internal formatting' do
    session.search(Post) do
      keywords 'test', :highlight => true
    end
    connection.should have_last_search_with(
      :"hl.simple.pre" => '@@@hl@@@',
      :"hl.simple.post" => '@@@endhl@@@'
    )
  end

  it 'should set maximum highlights per field' do
    session.search(Post) do
      keywords 'test', :highlight => { :max_snippets => 3 }
    end
    connection.should have_last_search_with(
      :"hl.snippets" => 3
    )
  end

  it 'should set the maximum size' do
    session.search(Post) do
      keywords 'text', :highlight => { :fragment_size => 200 }
    end
    connection.should have_last_search_with(
      :"hl.fragsize" => 200
    )
  end

  it 'enables merging of continuous fragments' do
    session.search(Post) do
      keywords 'test', :highlight => { :merge_continuous_fragments => true }
    end
    connection.should have_last_search_with(
      :"hl.mergeContinuous" => 'true'
    )
  end

  it 'enables use of phrase highlighter' do #TODO figure out what the hell this means
    session.search(Post) do
      keywords 'test', :highlight => { :phrase_highlighter => true }
    end
    connection.should have_last_search_with(
      :"hl.usePhraseHighlighter" => 'true'
    )
  end

  it 'requires field match if requested' do
    session.search(Post) do
      keywords(
        'test',
        :highlight => {
          :phrase_highlighter => true,
          :require_field_match => true
        }
      )
    end
    connection.should have_last_search_with(
      :"hl.requireFieldMatch" => 'true'
    )
  end
end
