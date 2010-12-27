class User
  attr_accessor :name, :roles

  def id
    1
  end
end

Sunspot.setup(User) do
  text :name
  string :name
  integer :role_ids, :multiple => true, :stored => true
end
