module Sunspot
  module Query
    #
    # A query component that builds parameters for requesting highlights
    #
    class Highlighting #:nodoc:
      def initialize(fields=[], options={})
        @fields  = fields
        @options = options
      end

      # 
      # Return Solr highlighting params
      #
      def to_params
        params = {
          :hl => 'on',
          :"hl.simple.pre" => '@@@hl@@@',
          :"hl.simple.post" => '@@@endhl@@@'
        }
        unless @fields.empty?
          params[:"hl.fl"] = @fields.map { |field| field.indexed_name }
        end
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
