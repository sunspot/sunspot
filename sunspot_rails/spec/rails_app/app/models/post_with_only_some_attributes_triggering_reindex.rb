class PostWithOnlySomeAttributesTriggeringReindex < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

  searchable :only_reindex_attribute_changes_of => [ :title, :body ] do
    string :title
    text :body, :more_like_this => true
  end
end
