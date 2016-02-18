%w(filter abstract_field_facet connective boost_query date_field_facet range_facet abstract_fulltext dismax join
   field_facet highlighting pagination restriction common_query spellcheck
   standard_query more_like_this more_like_this_query geo geofilt bbox query_facet
   scope sort sort_composite text_field_boost function_query field_stats
   composite_fulltext group group_query).each do |file|
  require(File.join(File.dirname(__FILE__), 'query', file))
end
module Sunspot
  module Query #:nodoc:all
  end
end
