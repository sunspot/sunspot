module Sunspot
  module Query
    class Bbox
      def initialize(field, first_corner, second_corner)
        @field, @first_corner, @second_corner = field, first_corner, second_corner
      end

      def to_params
        filter = "#{@field.indexed_name}:[#{@first_corner.join(",")} TO #{@second_corner.join(",")}]"

        {:fq => filter}
      end
    end
  end
end
