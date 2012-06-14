class PostWithDefaultScope < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

  default_scope :order => :title

  searchable :auto_index => false, :auto_remove => false do
    string :title
  end
end
