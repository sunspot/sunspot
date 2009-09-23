module Sunspot
  module Query
    class Scope < Connective::Conjunction
      def to_params
        { :fq => @components.map { |component| component.to_boolean_phrase }}
      end
    end
  end
end
