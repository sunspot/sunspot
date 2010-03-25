module Namespaced
  class Comment < MockRecord
    attr_reader :id
    attr_accessor :author_name, :published_at, :body, :average_rating, :boost,
                  :hash

    def custom_float
      @custom_float ||= {}
    end
  end
end

Sunspot.setup(Namespaced::Comment) do
  text :body, :author_name
  string :author_name
  time :published_at, :trie => true
  long :hash
  double :average_rating
  dynamic_float :custom_float, :multiple => true
  boost :boost
end
