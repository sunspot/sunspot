module Sunspot
  module Query
    class RegisteredParser
      def self.register(name,parser)
        @registered ||= {}
        @registered[name.to_sym] = parser if name
      end

      def self.get_parser(name)
        @registered[name.to_sym] if name
      end

    end
  end
end

%w(filter abstract_field_facet connective boost_query date_field_facet range_facet dismax
   field_facet highlighting pagination restriction common_query
   standard_query more_like_this more_like_this_query geo geofilt bbox query_facet
   scope sort sort_composite text_field_boost function_query
   composite_fulltext field_group extended_dismax).each do |file|
  require(File.join(File.dirname(__FILE__), 'query', file))
end
module Sunspot
  module Query #:nodoc:all
  end
end
