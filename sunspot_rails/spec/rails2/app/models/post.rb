class Post < ActiveRecord::Base
  belongs_to :location
  belongs_to :author

  searchable :auto_index => false, :auto_remove => false do
    string :title
    text :body, :more_like_this => true
    location :location
  end
end
