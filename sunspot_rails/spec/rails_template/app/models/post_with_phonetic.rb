class PostWithPhonetic < ActiveRecord::Base
  belongs_to :location
  belongs_to :author
  has_many :comments

  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

  searchable :auto_index => false, :auto_remove => false do
    text :title, :phonetic => true
    text :body, :more_like_this => true
    location :location
  end
end
