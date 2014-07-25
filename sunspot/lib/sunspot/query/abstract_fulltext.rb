module Sunspot
  module Query

    #
    # Solr query abstraction
    #
    class AbstractFulltext
      attr_reader :fulltext_fields

      private

      def escape_param(key, value)
        "#{key}='#{escape_quotes(Array(value).join(" "))}'"
      end

      def escape_quotes(value)
        return value unless value.is_a? String
        value.gsub(/(['"])/, '\\\\\1')
      end
    end
  end
end
