# This model should not be used for any test other than the spec test that
# checks if all models are loaded. We don't want to pre-load this model in
# another test because we're checking to see if it will be auto-loaded by
# the reindex task
class RakeTaskAutoLoadTestModel < ActiveRecord::Base
  def self.table_name
    'posts'
  end

  searchable do
    string :name
  end
end
