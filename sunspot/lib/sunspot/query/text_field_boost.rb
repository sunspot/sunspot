module Sunspot
  module Query
    class TextFieldBoost #:nodoc:
      attr_reader :boost

      def initialize(field, boost = nil)
        @field, @boost = field, boost
      end

      def to_boosted_field
        @boost ? "#{@field.indexed_name}^#{@boost}" : @field.indexed_name
      end
    end
  end
end
