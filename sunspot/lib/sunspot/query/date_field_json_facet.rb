module Sunspot
  module Query
    class DateFieldJsonFacet < RangeJsonFacet

      def initialize(field, options, setup)
        super
        @gap = "+#{@gap}#{options[:gap_unit] || 'SECONDS'}"
      end
    end
  end
end
