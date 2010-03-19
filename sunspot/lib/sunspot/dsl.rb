%w(fields scope paginatable adjustable field_query query query_facet fulltext restriction
   search more_like_this).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
