module Sunspot
  module Util
    class ClosedStruct
      def initialize(data)
        (class <<self; self; end).module_eval do
          data.each_pair do |attr_name, value|
            define_method(attr_name.to_s) { value }
          end
        end
      end
    end

    class <<self
      def deep_merge(left, right)
        deep_merge_into({}, left, right)
      end

      def deep_merge!(left, right)
        deep_merge_into(left, left, right)
      end

      private

      def deep_merge_into(destination, left, right)
        left.each_pair do |name, left_value|
          right_value = right[name]
          destination[name] =
            if right_value.nil? || left_value == right_value
              left_value
            elsif !left_value.respond_to?(:each_pair) || !right_value.respond_to?(:each_pair)
              Array(left_value) + Array(right_value)
            else
              merged_value = {}
              deep_merge_into(merged_value, left_value, right_value)
            end
        end
        left_keys = Set.new(left.keys)
        destination.merge!(right.reject { |k, v| left_keys.include?(k) })
        destination
      end
    end
  end
end
