%w(abstract_search standard_search more_like_this_search query_facet field_facet
   date_facet range_facet facet_row hit highlight field_group group hit_enumerable).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  module Search
  end
end
