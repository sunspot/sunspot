class User
  attr_accessor :name
end

Sunspot.setup(User) do
  text :name
  string :name
end
