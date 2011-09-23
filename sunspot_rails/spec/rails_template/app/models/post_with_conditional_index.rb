class PostWithConditionalIndex < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  searchable :auto_index => false, :auto_remove => false, :if => :title_is_present do
    string :title
  end

  def title_is_present
    title.present?
  end
end
