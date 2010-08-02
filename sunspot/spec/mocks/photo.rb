class Photo < MockRecord
  attr_accessor :caption, :lat, :lng, :size, :average_rating, :created_at
end

Sunspot.setup(Photo) do
  text :caption, :default_boost => 1.5
  boost 0.75
  integer :size, :trie => true
  float :average_rating, :trie => true
  time :created_at, :trie => true
end
