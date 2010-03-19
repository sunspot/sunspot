class Post < ActiveRecord::Base
  belongs_to :location

  searchable :auto_index => false, :auto_remove => false do
    string :title
    text :body, :more_like_this => true
    coordinates :location
  end
end
