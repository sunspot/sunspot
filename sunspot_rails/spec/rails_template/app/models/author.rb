class Author < ActiveRecord::Base
  self.table_name  = :writers
  self.primary_key = :writer_id

  attr_accessible :name

  searchable do
    string :name
  end
end
