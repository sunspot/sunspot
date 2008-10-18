class BaseClass
  include Sunspot::Searchable
end

class Post < BaseClass
  @@id = 0

  attr_reader :id
  attr_accessor :title, :body, :blog_id, :published_at, :average_rating, :author_name

  is_searchable do
    keywords :title, :body
    string :title
    integer :blog_id
    integer :category_ids
    float :average_rating
    time :published_at
    string :sort_title do
      title.downcase.sub(/^(a|an|the)\W+/, '') if title = self.title
    end
  end

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
