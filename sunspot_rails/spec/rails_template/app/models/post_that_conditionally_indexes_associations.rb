class PostThatConditionallyIndexesAssociations < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  attr_accessor :published
  attr_accessible :title, :blog, :published

  belongs_to :blog

  index_related :blog, if: :published
end
