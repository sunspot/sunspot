module Sunspot
  module Query
    class TextFieldBoost #:nodoc:
      attr_reader :boost

      def initialize(field, boost = nil)
        @field, @boost = field, boost
      end

      def to_boosted_field
        boosted_field = @field.indexed_name
        boosted_field.concat("^#{@boost}") if @boost
        boosted_field
      end
    end
  end
end
