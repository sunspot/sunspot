class Photo < MockRecord
  attr_accessor :caption, :description, :lat, :lng, :size, :average_rating, :created_at, :post_id, :photo_container_id
end

Sunspot.setup(Photo) do
  text :caption, :default_boost => 1.5
  text :description
  string :caption
  integer :photo_container_id
  boost 0.75
  integer :size, :trie => true
  float :average_rating, :trie => true
  time :created_at, :trie => true
end

class PhotoContainer < MockRecord
  attr_accessor :description

  def id
    1
  end
end

Sunspot.setup(PhotoContainer) do
  integer :id
  text :description, :default_boost => 1.2

  join(:caption, :target => Photo, :type => :string, :join => { :from => :photo_container_id, :to => :id })
  join(:photo_rating, :target => Photo, :type => :trie_float, :join => { :from => :photo_container_id, :to => :id }, :as => 'average_rating_ft')
  join(:caption, :target => Photo, :type => :text, :join => { :from => :photo_container_id, :to => :id })
  join(:description, :prefix => "photo", :target => Photo, :type => :text, :join => { :from => :photo_container_id, :to => :id })
end
