module Sunspot
  module Query
    class SortComposite
      def initialize
        @sorts = []
      end

      def <<(sort)
        @sorts << sort
      end

      def to_params
        unless @sorts.empty?
          { :sort => @sorts.map { |sort| sort.to_param } * ', ' }
        else
          {}
        end
      end
    end
  end
end
