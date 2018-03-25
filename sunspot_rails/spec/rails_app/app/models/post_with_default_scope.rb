class PostWithDefaultScope < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

	def self.default_scope
		order(:title)
  end

  searchable :auto_index => false, :auto_remove => false do
    string :title
  end
end
