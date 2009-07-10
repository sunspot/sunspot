module Sunspot
  class Search
    class Hit
      SPECIAL_KEYS = Set.new(%w(id type score))
      attr_reader :primary_key, :class_name, :score

      def initialize(raw_hit, search)
        @class_name, @primary_key = *raw_hit['id'].match(/([^ ]+) (.+)/)[1..2]
        @score = raw_hit['score']
        @search = search
        @stored_values = raw_hit
      end

      def stored
        @stored ||=
          @stored_values.inject({}) do |stored, (indexed_field_name, value)|
            unless SPECIAL_KEYS.include?(indexed_field_name)
              field_name = indexed_field_name.sub(/_[^_]+$/, '').to_sym
              field = @search.field(field_name)
              stored[field_name] = field.cast(value)
            end
            stored
          end
      end
    end
  end
end
