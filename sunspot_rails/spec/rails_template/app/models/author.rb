class Author < ActiveRecord::Base
  set_table_name :writers
  set_primary_key :writer_id

  attr_accessible :name

  searchable do
    string :name
  end
end
