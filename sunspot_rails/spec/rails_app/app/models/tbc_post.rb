class TbcPost < ActiveRecord::Base
  attr_writer :collection_postfix

  searchable :auto_index => false, :auto_remove => false do
    text :title
    text :body, :more_like_this => true
  end

  def collection_postfix
    @collection_postfix || 'hr'
  end

  def time_routed_on
    Time.new(2009, 10, 1, 12, 30, 0)
  end

  def self.select_valid_connection(collections)
    collections.select do |c|
      c.end_with?('_hr', '_rt')
    end
  end
end

class TbcPostWrong < Post
end

class TbcPostWrongTime < Post
  def collection_postfix
    'hr'
  end
  def time_routed_on
    DateTime.new(2009, 10, 1, 12, 30, 0)
  end
end
