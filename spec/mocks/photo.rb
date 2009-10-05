class Photo < MockRecord
  attr_accessor :caption
end

Sunspot.setup(Photo) do
  text :caption, :default_boost => 1.5
  boost 0.75
end
