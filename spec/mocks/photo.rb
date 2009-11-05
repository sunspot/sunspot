class Photo < MockRecord
  attr_accessor :caption
  attr_accessor :lat
  attr_accessor :lng
end

Sunspot.setup(Photo) do
  text :caption, :default_boost => 1.5
  boost 0.75
  coordinates { [lat, lng] }
end
