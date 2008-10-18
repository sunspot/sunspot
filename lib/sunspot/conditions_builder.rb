module Sunspot
  class ConditionsBuilder
    def initialize(query)
      @query = query
    end

    def method_missing(field_name, *args)
      if args.length == 0 then ConditionBuilder.new(field_name)
      elsif args.length == 1 then @query.build_condition field_name, ::Sunspot::Condition::EqualTo, args.first
      else super(field_name.to_sym, *args)
      end
    end
  end
end
