if Rails::VERSION::MAJOR == 2
  Sunspot.config.indexing.auto_index_callback = :after_save
else
  Sunspot.config.indexing.auto_index_callback = :after_commit
end
