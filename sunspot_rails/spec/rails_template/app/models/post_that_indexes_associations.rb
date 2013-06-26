class PostThatIndexesAssociations < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessible :title, :blog

  belongs_to :blog

  index_related :blog
end
