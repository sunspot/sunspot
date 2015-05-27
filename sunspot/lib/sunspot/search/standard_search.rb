module Sunspot
  module Search
    #
    # This class encapsulates the results of a Solr search. It provides access
    # to search results, total result count, facets, and pagination information.
    # Instances of Search are returned by the Sunspot.search and
    # Sunspot.new_search methods.
    #
    class StandardSearch < AbstractSearch
      def request_handler
        super || :select
      end

      # Return the raw spellcheck block from the Solr response
      def solr_spellcheck
        @solr_spellcheck ||= @solr_result['spellcheck'] || {}
      end

      # Reformat the oddly-formatted spellcheck suggestion array into a
      # more useful hash.
      #
      # Original: [term, suggestion, term, suggestion, ..., "correctlySpelled", bool, "collation", str]
      #           "collation" is only included if spellcheck.collation was set to true
      # Returns: { term => suggestion, term => suggestion }
      def spellcheck_suggestions
        unless defined?(@spellcheck_suggestions)
          @spellcheck_suggestions = {}
          count = ((solr_spellcheck['suggestions'] || []).length) / 2
          (0..(count - 1)).each do |i|
            break if ["correctlySpelled", "collation"].include? solr_spellcheck[i]
            term = solr_spellcheck['suggestions'][i * 2]
            suggestion = solr_spellcheck['suggestions'][(i * 2) + 1]
            @spellcheck_suggestions[term] = suggestion
          end
        end
        @spellcheck_suggestions
      end

      # Return the suggestion with the single highest frequency.
      # Requires the extended results format.
      def spellcheck_suggestion_for(term)
        spellcheck_suggestions[term]['suggestion'].sort_by do |suggestion|
          suggestion['freq']
        end.last['word']
      end

      # Provide a collated query. If the user provides a query string,
      # tokenize it on whitespace and replace terms strictly not present in
      # the index. Otherwise return Solr's suggested collation.
      #
      # Solr's suggested collation is more liberal, replacing even terms that
      # are present in the index. This may not be useful if only one term is
      # misspelled and preventing useful results.
      #
      # Mix and match in your views for a blend of strict and liberal collations.
      def spellcheck_collation(*terms)
        if solr_spellcheck['suggestions'] && solr_spellcheck['suggestions'].length > 2
          collation = terms.join(" ").dup if terms

          # If we are given a query string, tokenize it and strictly replace
          # the terms that aren't present in the index
          if terms.length > 0
            terms.each do |term|
              if (spellcheck_suggestions[term]||{})['origFreq'] == 0
                collation[term] = spellcheck_suggestion_for(term)
              end
            end
          end

          # If no query was given, or all terms are present in the index,
          # return Solr's suggested collation.
          if terms.length == 0
            collation = solr_spellcheck['collations'][-1]
          end

          collation
        else
          nil
        end
      end

      private

      def dsl
        DSL::Search.new(self, @setup)
      end
    end
  end
end
