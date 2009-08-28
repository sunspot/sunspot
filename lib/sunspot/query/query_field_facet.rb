module Sunspot
  module Query
    class QueryFieldFacet < QueryFacet
      def initialize(field, values)
        super(field.name)
        @field = field
        values.each do |value|
          add_row(value).add_component(Restriction::EqualTo.new(field, value))
        end
      end
    end
  end
end
