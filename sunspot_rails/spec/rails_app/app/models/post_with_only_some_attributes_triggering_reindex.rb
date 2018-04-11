class PostWithOnlySomeAttributesTriggeringReindex < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  searchable :only_reindex_attribute_changes_of => [ :title, :body ] do
    string :title
    text :body, :more_like_this => true
  end
end
