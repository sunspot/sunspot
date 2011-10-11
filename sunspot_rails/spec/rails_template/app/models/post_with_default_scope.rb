class PostWithDefaultScope < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  default_scope :order => :title

  searchable :auto_index => false, :auto_remove => false do
    string :title
  end
end
