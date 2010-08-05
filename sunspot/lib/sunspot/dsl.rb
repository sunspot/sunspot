%w(fields scope paginatable adjustable field_query standard_query query_facet
   functional fulltext restriction restriction_with_near search
   more_like_this_query function).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
