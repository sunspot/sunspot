if Sunspot::Util.child_documents_supported?
  class Book < MockRecord
    attr_accessor :title
    attr_accessor :author
    attr_accessor :category
    attr_accessor :pub_year
    attr_accessor :reviews
  end

  Sunspot.setup(Book) do
    text    :title
    string  :author
    string  :category
    integer :pub_year

    child_documents :reviews
  end

  class Review < MockRecord
    attr_accessor :book_id
    attr_accessor :review_date
    attr_accessor :stars
    attr_accessor :author
    attr_accessor :comment
  end

  Sunspot.setup(Review) do
    integer :book_id
    time    :review_date
    integer :stars
    string  :author
    text    :comment
  end
end