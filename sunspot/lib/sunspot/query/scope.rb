module Sunspot
  module Query
    class Scope < Connective::Conjunction
      def to_params
        filters = []
        @components.each do |component|
          filter = component.to_filter_query
          filters << filter unless filter.nil?
        end
        if filters.empty? then {}
        else { :fq => filters}
        end
      end
    end
  end
end
