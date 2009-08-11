%w(fields scope field_query query query_facet restriction search).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
