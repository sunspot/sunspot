require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'multiselect faceting' do
  it 'tags and excludes a scope filter in a field facet' do
    session.search(Post) do
      blog_filter = with(:blog_id, 1)
      facet(:blog_id, :exclude => blog_filter)
    end
    filter_tag = get_filter_tag('blog_id_i:1')
    connection.should have_last_search_with(
      :"facet.field" => %W({!ex=#{filter_tag}}blog_id_i)
    )
  end

  it 'does not tag a filter if it is not excluded' do
    session.search(Post) do
      with(:blog_id, 1)
    end
    connection.should have_last_search_including(:fq, "blog_id_i:1")
  end

  private

  def get_filter_tag(boolean_query)
    connection.searches.last[:fq].each do |fq|
      if match = fq.match(/^\{!tag=(.+)\}#{Regexp.escape(boolean_query)}$/)
        return match[1]
      end
    end
    nil
  end
end
