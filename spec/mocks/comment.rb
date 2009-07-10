module Namespaced
  class Comment < MockRecord
    attr_reader :id
    attr_accessor :author_name, :published_at, :body, :average_rating
  end
end

Sunspot.setup(Namespaced::Comment) do
  text :body
  string :author_name
  time :published_at
  integer :average_rating
end
