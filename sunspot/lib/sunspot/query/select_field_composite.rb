module Sunspot
  module Query
    #
    # The SelectFieldComposite class encapsulates an ordered collection of Field
    # objects. It's necessary to keep this as a separate class as Solr takes
    # the sort as a single parameter, so adding fields as regular components
    # would not merge correctly in the #to_params method.
    #
    class SelectFieldComposite #:nodoc:
      attr_reader :fields

      def initialize
        @fields = []
      end

      #
      # Add a field to the composite
      #
      def <<(field)
        @fields << field.compact.join(':')
      end

      #
      # Pull all special fields from hit definition
      #
      def default_fields
        Sunspot::Search::Hit::SPECIAL_KEYS.to_a
      end

      #
      # Combine the sorts into a single param by joining them
      #
      def to_params(fl = [])
        fl = Array(fl).flat_map { |field| field.split(/[\s,]+/) }
        if fields.empty?
          fl << '*'
        else fields.empty?
          fl.delete('*')
          fl.concat(fields)
          fl.concat(default_fields)
        end
        { fl: fl.compact.uniq.join(' ') }
      end

    end
  end
end
