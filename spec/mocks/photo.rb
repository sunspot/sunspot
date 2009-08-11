class Photo < MockRecord
  attr_accessor :caption
end

Sunspot.setup(Photo) do
  text :caption
  boost 0.75
end
