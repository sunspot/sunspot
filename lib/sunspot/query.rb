%w(connective boost_query dismax field_facet highlighting local pagination restriction query query_facet query_field_facet query_facet_row scope sort sort_composite text_field_boost).each { |file| require(File.join(File.dirname(__FILE__), 'query', file)) }
module Sunspot
  module Query #:nodoc:all
  end
end
