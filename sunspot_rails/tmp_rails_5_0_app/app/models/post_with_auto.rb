class PostWithAuto < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

  searchable :ignore_attribute_changes_of => [ :updated_at ] do
    string :title
    text :body, :more_like_this => true
  end
end
