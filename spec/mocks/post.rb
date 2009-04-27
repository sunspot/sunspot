class Post < BaseClass
  @@id = 0
  @@posts = [nil]

  attr_reader :id
  attr_accessor :title, :body, :blog_id, :published_at, :ratings_average, :author_name


  def initialize(attrs = {})
    @id = @@id += 1
    @@posts << self
    attrs.each_pair { |attribute, value| self.send "#{attribute}=", value }
  end

  def category_ids
    @category_ids ||= []
  end

  def self.get(id)
    @@posts[id]
  end

  def self.get_all(ids)
    ids.map { |id| get(id) }.sort_by { |post| post.id } # this is so that results are not ordered by coincidence
  end

  private
  attr_writer :category_ids
end

Sunspot.setup(Post) do
  text :title, :body
  string :title
  integer :blog_id
  integer :category_ids, :multiple => true
  float :average_rating, :using => :ratings_average
  time :published_at
  string :sort_title do
    title.downcase.sub(/^(a|an|the)\W+/, '') if title
  end
end
