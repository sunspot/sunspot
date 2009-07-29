module Sunspot
  module Query
    #
    # A query component that provides access to hit highlighting in Solr
    #
    class Highlighting #:nodoc:
      def initialize
      end
      
      def to_params
        {:hl => 'on'}
      end
    end
  end
end