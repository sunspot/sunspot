module Sunspot
  module DSL
    class Scope
      def initialize(query, negative = false)
        @query, @negative = query, negative
      end

      def method_missing(field_name, *args)
        if args.length == 0 
          RestrictionBuilder.new(field_name, @query, @negative)
        elsif args.length == 1
          scope = @query.build_condition(field_name, ::Sunspot::Restriction::EqualTo, args.first)
          unless @negative
            @query.add_scope(scope)
          else
            @query.add_negative_scope(scope)
          end
        else
          super(field_name.to_sym, *args)
        end
      end

      class RestrictionBuilder
        def initialize(field_name, query, negative)
          @field_name, @query, @negative = field_name, query, negative
        end

        def method_missing(condition_name, *args)
          clazz = begin
                    ::Sunspot::Restriction.const_get(condition_name.to_s.camel_case)
                  rescue(NameError)
                    super(condition_name.to_sym, *args)
                  end
          scope = @query.build_condition(@field_name, clazz, args.first)
          unless @negative
            @query.add_scope(scope)
          else
            @query.add_negative_scope(scope)
          end
        end
      end
    end
  end
end
