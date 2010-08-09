class PostWithAuto < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  searchable :ignore_attribute_changes_of => [ :updated_at ] do
    string :title
    text :body, :more_like_this => true
  end
end
