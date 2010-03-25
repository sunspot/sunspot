%w(filter abstract_field_facet connective boost_query date_field_facet dismax
   field_facet highlighting local pagination restriction query
   query_facet scope sort sort_composite text_field_boost function_query).each do |file|
  require(File.join(File.dirname(__FILE__), 'query', file))
end
module Sunspot
  module Query #:nodoc:all
  end
end
