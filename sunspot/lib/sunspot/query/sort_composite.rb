module Sunspot
  module Query
    # 
    # The SortComposite class encapsulates an ordered collection of Sort
    # objects. It's necessary to keep this as a separate class as Solr takes
    # the sort as a single parameter, so adding sorts as regular components
    # would not merge correctly in the #to_params method.
    #
    class SortComposite #:nodoc:
      def initialize
        @sorts = []
      end

      # 
      # Add a sort to the composite
      #
      def <<(sort)
        @sorts << sort
      end

      # 
      # Combine the sorts into a single param by joining them
      #
      def to_params(prefix = "")
        unless @sorts.empty?
          key = "#{prefix}sort".to_sym
          { key => @sorts.map { |sort| sort.to_param } * ', ' }
        else
          {}
        end
      end
    end
  end
end
