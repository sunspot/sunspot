require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'search with highlighting results', :type => :search do
  before :each do
    @posts = Array.new(2) { Post.new }
    stub_results_with_highlighting(
      @posts[0],
      { 'title_text' => ['one @@@hl@@@two@@@endhl@@@ three'] },
      @posts[1],
      { 'title_text' => ['three four @@@hl@@@five@@@endhl@@@'],
        'body_text' => ['@@@hl@@@five@@@ six seven', '@@@hl@@@eight@@@endhl@@@ nine @@@hl@@@ten@@@endhl@@@'] }
    )
    @search = session.search(Post)
  end

  it 'returns all highlights' do
    @search.hits.last.should have(3).highlights
  end

  it 'returns all highlights for a specified field' do
    @search.hits.last.should have(2).highlights(:body)
  end

  it 'returns first highlight for a specified field' do
    @search.hits.first.highlight(:title).format.should == 'one <em>two</em> three'
  end

  it 'returns an empty array if a given field does not have a highlight' do
    @search.hits.first.highlights(:body).should == []
  end

  it 'formats hits with <em> by default' do
    highlight = @search.hits.first.highlights(:title).first.formatted
    highlight.should == 'one <em>two</em> three'
  end

  it 'formats hits with provided block' do
    highlight = @search.hits.first.highlights(:title).first.format do |word|
      "<i>#{word}</i>"
    end
    highlight.should == 'one <i>two</i> three'
  end

  it 'handles multiple highlighted words' do
    highlight = @search.hits.last.highlights(:body).last.format do |word|
      "<b>#{word}</b>"
    end
    highlight.should == '<b>eight</b> nine <b>ten</b>'
  end

  private

  def stub_results_with_highlighting(*instances_and_highlights)
    docs, highlights = [], []
    instances_and_highlights.each_slice(2) do |doc, highlight|
      docs << doc
      highlights << highlight
    end
    response = stub_full_results(*docs.map { |doc| { 'instance' => doc }})
    highlighting = response['highlighting'] = {}
    highlights.each_with_index do |highlight, i|
      if highlight
        instance = docs[i]
        highlighting["#{instance.class.name} #{instance.id}"] = highlight
      end
    end
    response
  end
end
