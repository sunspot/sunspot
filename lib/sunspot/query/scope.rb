module Sunspot
  module Query
    class Scope < Connective::Conjunction
      def to_params
        { :fq => @components.map { |component| component.to_filter_query }}
      end
    end
  end
end
