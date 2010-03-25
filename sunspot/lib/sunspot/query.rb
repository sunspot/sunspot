%w(filter abstract_field_facet connective boost_query date_field_facet dismax
   field_facet highlighting local pagination restriction common_query
   standard_query more_like_this more_like_this_query query_facet scope sort
   sort_composite text_field_boost function_query composite_fulltext).each do |file|
  require(File.join(File.dirname(__FILE__), 'query', file))
end
module Sunspot
  module Query #:nodoc:all
  end
end
