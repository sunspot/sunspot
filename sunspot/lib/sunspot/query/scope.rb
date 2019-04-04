module Sunspot
  module Query
    class Scope < Connective::Conjunction
      def to_params
        { :fq => @components.map(&:to_filter_query).compact }
      end
    end
  end
end
