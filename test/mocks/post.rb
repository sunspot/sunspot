class BaseClass
end

class Post < BaseClass
  @@id = 0

  attr_reader :id
  attr_accessor :title, :body, :blog_id, :published_at, :average_rating, :author_name


  def initialize(attrs = {})
    @id = @@id += 1
    attrs.each_pair { |attribute, value| self.send "#{attribute}=", value }
  end

  def category_ids
    @category_ids ||= []
  end

  private
  attr_writer :category_ids
end

Sunspot.setup(Post) do
  text :title, :body
  string :title
  integer :blog_id
  integer :category_ids, :multiple => true
  float :average_rating
  time :published_at
  string :sort_title do
    title.downcase.sub(/^(a|an|the)\W+/, '') if title
  end
end
