module Sunspot
  module Query
    module Filter

      # 
      # Express this filter as an :fq parameter; i.e., the boolean phrase,
      # maybe prefixed by local params.
      #
      def to_filter_query
        if tagged? then "{!tag=#{tag}}#{to_boolean_phrase}"
        else to_boolean_phrase
        end
      end

      #
      # Generate and return a tag that can be attached to this restriction,
      # for use with multiselect faceting. This needs to be unique, but doesn't
      # really need to be human-readable, so just generate a string based on the
      # hash of the boolean phrase.
      #
      def tag
        @tag ||= to_boolean_phrase.hash.abs.to_s(36)
      end
      
      private

      # 
      # True if a tag has been generated for this filter (e.g., if it's been
      # excluded from a given facet). If a tag has not been generated at the
      # time that the filter query param is requested, then it is not necessary
      # to include a tag in the local params.
      #
      def tagged?
        defined?(@tag) && !!@tag
      end
    end
  end
end
