class Post < ActiveRecord::Base
  belongs_to :location
  belongs_to :author
  has_many :comments

  searchable :auto_index => false, :auto_remove => false do
    string :title
    text :body, :more_like_this => true
    location :location
  end

  scope :includes_location, -> {
    includes(:location)
  }

  def time_routed_on
    DateTime.new(year: created_at.year, month: created_at.month, day: created_at.day)
  end

  def collection_postfix
    @collection_postfix || 'hr'
  end

  attr_writer :collection_postfix
end
