module Sunspot
  module Query
    class TextFieldBoost #:nodoc:
      attr_reader :boost

      def initialize(field, boost = nil)
        @field, @boost = field, boost
      end

      def to_boosted_field
        field_name = @field.indexed_name
        @boost ? field_name + "^#{@boost}" : field_name
      end
    end
  end
end
