module Namespaced
  class Comment < MockRecord
    attr_reader :id
    attr_accessor :author_name, :published_at, :body, :average_rating, :boost

    def custom_string
      @custom_string ||= {}
    end
  end
end

Sunspot.setup(Namespaced::Comment) do
  text :body, :author_name
  string :author_name
  time :published_at
  integer :average_rating
  dynamic_string :custom_string
  boost :boost
end
