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
end
