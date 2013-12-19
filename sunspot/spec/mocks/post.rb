require File.join(File.dirname(__FILE__), 'blog')
require File.join(File.dirname(__FILE__), 'super_class')

class Post < SuperClass
  attr_accessor :title, :body, :blog_id, :published_at, :ratings_average,
                :author_name, :featured, :expire_date, :coordinates, :tags
  alias_method :featured?, :featured

  def category_ids
    @category_ids ||= []
  end

  def custom_string
    @custom_string ||= {}
  end

  def custom_fl
    @custom_fl ||= {}
  end

  def custom_time
    @custom_time ||= {}
  end

  def custom_boolean
    @custom_boolean ||= {}
  end

  private
  attr_writer :category_ids, :custom_string, :custom_fl, :custom_time, :custom_boolean
end

Sunspot.setup(Post) do
  text :title, :boost => 2
  text :body, :stored => true, :more_like_this => true
  text :backwards_title do
    title.reverse if title
  end
  text :tags, :more_like_this => true
  string :title, :stored => true
  integer :blog_id, :references => Blog
  integer :category_ids, :multiple => true
  float :average_rating, :using => :ratings_average, :trie => true
  time :published_at, :trie => true
  date :expire_date
  boolean :featured, :using => :featured?, :stored => true
  string :sort_title do
    title.downcase.sub(/^(a|an|the)\W+/, '') if title
  end
  integer :primary_category_id do |post|
    post.category_ids.first
  end
  time :last_indexed_at, :stored => true do
    Time.now
  end
  location :coordinates
  latlon(:coordinates_new) { coordinates }

  dynamic_string :custom_string, :stored => true
  dynamic_float :custom_float, :multiple => true, :using => :custom_fl
  dynamic_integer :custom_integer do
    category_ids.inject({}) do |hash, category_id|
      hash.merge(category_id => 1)
    end
  end
  dynamic_time :custom_time
  dynamic_boolean :custom_boolean

  boost do
    if ratings_average
      1 + (ratings_average - 3.0) / 4.0
    end
  end

  string :legacy, :as => :legacy_field_s do
    "legacy #{title}"
  end

  string :legacy_array, :as => :legacy_array_field_sm, :multiple => true do
    ['first string', 'second string']
 	end
end

class PhotoPost < Post
end

