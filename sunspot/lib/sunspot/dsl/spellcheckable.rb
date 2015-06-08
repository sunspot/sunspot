module Sunspot
  module DSL #:nodoc:
    module Spellcheckable #:nodoc
      # Ask Solr to suggest alternative spellings for the query
      #
      # ==== Options
      #
      # The list of options can be found here: http://wiki.apache.org/solr/SpellCheckComponent
      def spellcheck(options = {})
        @query.add_spellcheck(options)
      end
    end
  end
end
