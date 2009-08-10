module Sunspot
  module Query
    #
    # A query component that provides access to hit highlighting in Solr
    #
    class Highlighting #:nodoc:
      def initialize(options)
        @options =
          if options == true
            {}
          else
            options
          end
      end

      def to_params
        params = {
          :hl => 'on',
          :"hl.simple.pre" => '@@@hl@@@',
          :"hl.simple.post" => '@@@endhl@@@'
        }
        if max_snippets = @options[:max_snippets]
          params[:"hl.snippets"] = max_snippets
        end
        if fragment_size = @options[:fragment_size]
          params[:"hl.fragsize"] = fragment_size
        end
        if @options[:merge_continuous_fragments]
          params[:"hl.mergeContinuous"] = 'true'
        end
        if @options[:phrase_highlighter]
          params[:"hl.usePhraseHighlighter"] = 'true'
          if @options[:require_field_match]
            params[:"hl.requireFieldMatch"] = 'true'
          end
        end
        params
      end
    end
  end
end
