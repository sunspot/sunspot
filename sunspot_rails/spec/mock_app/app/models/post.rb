class Post < ActiveRecord::Base
  belongs_to :location

  searchable :auto_index => false, :auto_remove => false do
    string :title
    coordinates :location
  end
end
