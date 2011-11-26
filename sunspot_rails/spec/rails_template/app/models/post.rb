class Post < ActiveRecord::Base
  belongs_to :location
  belongs_to :author
  has_many :comments

  named_scope :no_test_in_title, :conditions => "title NOT LIKE '%Test%'"

  searchable :auto_index => false, :auto_remove => false do
    string :title
    text :body, :more_like_this => true
    location :location
  end
end
