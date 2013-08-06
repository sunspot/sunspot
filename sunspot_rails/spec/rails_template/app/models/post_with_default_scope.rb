class PostWithDefaultScope < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :type, :location_id, :body, :blog

  default_scope :order => :title # Don't worry about Rails 4.0 deprecation warning as this is also used in Rails 3.x tests

  searchable :auto_index => false, :auto_remove => false do
    string :title
  end
end
