require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'facet local params' do
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

  it 'tags and excludes a disjunction filter in a field facet' do
    session.search(Post) do
      blog_filter = any_of do
        with(:blog_id, 1)
        with(:blog_id, 2)
      end
      facet(:blog_id, :exclude => blog_filter)
    end
    filter_tag = get_filter_tag('(blog_id_i:1 OR blog_id_i:2)')
    connection.should have_last_search_with(
      :"facet.field" => %W({!ex=#{filter_tag}}blog_id_i)
    )
  end

  it 'tags and excludes multiple filters in a field facet' do
    session.search(Post) do
      blog_filter = with(:blog_id, 1)
      category_filter = with(:category_ids, 2)
      facet(:blog_id, :exclude => [blog_filter, category_filter])
    end
    filter_tags = %w(blog_id_i:1 category_ids_im:2).map do |phrase|
      get_filter_tag(phrase)
    end.join(',')
    connection.should have_last_search_with(
      :"facet.field" => %W({!ex=#{filter_tags}}blog_id_i)
    )
  end

  it 'does not tag a filter if it is not excluded' do
    session.search(Post) do
      with(:blog_id, 1)
    end
    connection.should have_last_search_including(:fq, "blog_id_i:1")
  end

  it 'names a field facet' do
    session.search(Post) do
      facet(:blog_id, :name => :blog)
    end
    connection.should have_last_search_including(:"facet.field", "{!key=blog}blog_id_i")
  end

  it 'uses the custom field facet name in facet option parameters' do
    session.search(Post) do
      facet(:blog_id, :name => :blog, :sort => :count)
    end
    connection.should have_last_search_with(:"f.blog.facet.sort" => 'true')
  end

  it 'raises an ArgumentError if exclusion attempted on a query facet' do
    lambda do
      session.search(Post) do
        blog_filter = with(:blog_id, 1)
        facet(:bad, :exclude => blog_filter) do
          row(:bogus) { with(:blog_id, 1) }
        end
      end
    end.should raise_error(ArgumentError)
  end

  it 'raises an ArgumentError if exclusion attempted on a restricted field facet' do
    lambda do
      session.search(Post) do
        blog_filter = with(:blog_id, 1)
        facet(:blog_id, :only => 1, :exclude => blog_filter)
      end
    end.should raise_error(ArgumentError)
  end

  it 'raises an ArgumentError if exclusion attempted on a facet with :extra' do
    lambda do
      session.search(Post) do
        blog_filter = with(:blog_id, 1)
        facet(:blog_id, :extra => :all, :exclude => blog_filter)
      end
    end.should raise_error(ArgumentError)
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
