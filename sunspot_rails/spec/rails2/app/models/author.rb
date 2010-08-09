class Author < ActiveRecord::Base
  set_table_name :writers
  set_primary_key :writer_id

  searchable do
    string :name
  end
end
