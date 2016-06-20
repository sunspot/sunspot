module Sunspot
  module Query #:nodoc:

    # This DSL represents only fields that would come out of the results of the search type.
    class FieldList
      def initialize(list)
        @list = list
      end

      def to_params
        { :fl => @list }
      end
    end
  end
end
