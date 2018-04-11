class Author < ActiveRecord::Base
  self.table_name  = :writers
  self.primary_key = :writer_id

  searchable do
    string :name
  end
end
