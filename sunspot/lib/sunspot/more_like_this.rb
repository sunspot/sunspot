%w(abstract_search query_facet field_facet date_facet facet_row hit
   highlight).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

module Sunspot
  # 
  # This class encapsulates the results of a Solr MoreLikeThis search. It provides access
  # to search results, total result count, and pagination information.
  # Instances of MoreLikeThis are returned by the Sunspot.more_like_this and
  # Sunspot.new_more_like_this methods.
  #
  class MoreLikeThis < AbstractSearch

    def this_object=(object)
      @query.scope.add_restriction(
	IdField.instance,
	Sunspot::Query::Restriction::EqualTo,
	Sunspot::Adapters::InstanceAdapter.adapt(object).index_id
      )
      @setup.all_more_like_this_fields.each { |field| @query.add_field(field) }
    end

    private

    # override
    def dsl
      DSL::MoreLikeThis.new(@query, @setup)
    end

    def execute_request(params)
      @connection.mlt(params)
    end
  end
end
