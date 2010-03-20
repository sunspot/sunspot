class Blog < ActiveRecord::Base
  has_many :posts

  searchable :include => :posts do
    string :subdomain
    text :name
  end
end
