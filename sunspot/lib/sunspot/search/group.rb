require 'sunspot/search/hit_enumerable'

module Sunspot
  module Search
    class Group
      attr_reader :value

      include HitEnumerable

      def initialize(value, doclist, search)
        @value, @doclist, @search = value, doclist, search
      end

      def hits(options = {})
        if options[:verify]
          super
        else
          @hits ||= super
        end
      end

      def verified_hits
        @verified_hits ||= super
      end

      def results
        @results ||= verified_hits.map { |hit| hit.instance }
      end

      def highlights_for(doc)
        @search.highlights_for(doc)
      end

      def solr_docs
        @doclist['docs']
      end
      
      def data_accessor_for(clazz)
        @search.data_accessor_for(clazz)
      end      
      
      #
      # The total number of documents matching the query for this group
      #
      # ==== Returns
      #
      # Integer:: Total matching documents
      # 
      def total
        @doclist['numFound']
      end      
    end
  end
end
