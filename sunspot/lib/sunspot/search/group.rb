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

      def highlights_for(doc)
        @search.highlights_for(doc)
      end

      def solr_docs
        @doclist['docs']
      end
    end
  end
end
