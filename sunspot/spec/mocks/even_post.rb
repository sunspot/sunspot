class EvenPost < Post
  Sunspot.setup(EvenPost) do
    string :title
  end

  class << self
    def get_all(ids)
      super.reject { |object| object.id % 2 == 1 }
    end
  end
end
