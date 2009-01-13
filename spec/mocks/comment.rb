class Comment < BaseClass
  @@id = 0
  @@comments = [nil]

  attr_reader :id
  attr_accessor :author_name, :published_at, :body

  def initialize(attrs = {})
    @id = @@id += 1
    @@comments << self
    attrs.each_pair { |attribute, value| self.send("#{attribute}=", value) }
  end

  def self.get(id)
    @@posts[id]
  end

  def self.get_all(ids)
    ids.map { |id| get(id) }.sort_by { |post| post.id } # this is so that results are not ordered by coincidence
  end
end

Sunspot.setup(Comment) do
  text :author_name, :body
  string :author_name
  time :published_at
  integer :average_rating
end
