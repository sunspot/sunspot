module Sunspot
  # 
  # This class encapsulates the results of a Solr MoreLikeThis search. It provides access
  # to search results, total result count, and pagination information.
  # Instances of MoreLikeThis are returned by the Sunspot.more_like_this and
  # Sunspot.new_more_like_this methods.
  #
  module Search
    class MoreLikeThisSearch < AbstractSearch
      def execute
        if @query.more_like_this.fields.empty?
          @setup.all_more_like_this_fields.each do |field|
            @query.more_like_this.add_field(field)
          end
        end
        super
      end

      def request_handler
        super || :mlt
      end

      private

      # override
      def dsl
        DSL::MoreLikeThisQuery.new(self, @query, @setup)
      end
    end
  end
end
