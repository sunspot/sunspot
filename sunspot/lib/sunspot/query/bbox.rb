module Sunspot
  module Query
    class Bbox
      def initialize(field, first_corner, second_corner)
        @field, @first_corner, @second_corner = field, first_corner, second_corner
      end

      def to_solr_conditional
        "[#{@first_corner.join(",")} TO #{@second_corner.join(",")}]"
      end

      def to_params
        filter = "#{@field.indexed_name}:#{to_solr_conditional}"

        {:fq => filter}
      end
    end
  end
end
