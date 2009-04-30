class Post < ActiveRecord::Base
  searchable do
    string :title
  end
end
