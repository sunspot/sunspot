%w(fields scope paginatable adjustable field_query standard_query query_facet fulltext restriction
   search more_like_this_query function functional).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
