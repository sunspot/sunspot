%w(abstract_search standard_search more_like_this_search query_facet field_facet field_json_facet
   date_facet date_json_facet range_facet range_stat_json_facet range_json_facet distinct_json_facet
   facet_row hit highlight field_group group hit_enumerable
   stats_row field_stats stats_facet query_group).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  module Search
  end
end
