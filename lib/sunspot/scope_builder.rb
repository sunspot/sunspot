module Sunspot
  class ScopeBuilder
    def initialize(query)
      @query = query
    end

    def method_missing(field_name, *args)
      if args.length == 0 then RestrictionBuilder.new(field_name, @query)
      elsif args.length == 1 then @query.add_scope @query.build_condition(field_name, ::Sunspot::Restriction::EqualTo, args.first)
      else super(field_name.to_sym, *args)
      end
    end

    class RestrictionBuilder
      def initialize(field_name, query)
        @field_name, @query = field_name, query
      end

      def method_missing(condition_name, *args)
        clazz = begin
                  ::Sunspot::Restriction.const_get(condition_name.to_s.camel_case)
                rescue(NameError)
                  super(condition_name.to_sym, *args)
                end
        if value = args.first
          @query.add_scope @query.build_condition(@field_name, clazz, args.first)
        else
          @query.interpret_condition @field_name, clazz
        end
      end
    end
  end
end
