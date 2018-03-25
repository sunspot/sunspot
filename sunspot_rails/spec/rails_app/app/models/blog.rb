class Blog < ActiveRecord::Base
  has_many :posts
  has_many :comments, :through => :posts

  attr_accessible :name, :subdomain

  searchable :include => { :posts => :author } do
    string :subdomain
    text :name
  end

  # Make sure that includes are added to with multiple searchable calls
  searchable(:include => :comments) {}
end
