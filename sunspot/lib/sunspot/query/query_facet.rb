module Sunspot
  module Query
    class QueryFacet < Connective::Conjunction
      def to_params
        if @components.empty?
          {}
        else
          {
            :facet => 'true',
            :"facet.query" => to_boolean_phrase
          }
        end
      end
    end
  end
end
