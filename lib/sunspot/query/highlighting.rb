module Sunspot
  module Query
    #
    # A query component that provides access to hit highlighting in Solr
    #
    class Highlighting #:nodoc:
      def to_params
        {
          :hl => 'on',
          :"hl.simple.pre" => '@@@hl@@@',
          :"hl.simple.post" => '@@@endhl@@@'
        }
      end
    end
  end
end
