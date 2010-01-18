class Post < ActiveRecord::Base
  searchable :auto_index => false, :auto_remove => false do
    string :title
  end
end
