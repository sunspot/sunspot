class PostWithAuto < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  searchable do
    string :title
  end
end
