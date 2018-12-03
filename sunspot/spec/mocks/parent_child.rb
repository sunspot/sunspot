if Sunspot::Util.child_documents_supported?
  class Person < MockRecord
    attr_accessor :name, :surname, :age
  end

  class Child < Person
  end

  class Parent < Person
    attr_accessor :children
  end

  Sunspot.setup(Child) do
    string  :name
    string  :surname
    integer :age
  end

  Sunspot.setup(Parent) do
    string  :name
    string  :surname
    integer :age

    child_documents :children
  end
end