module Sunspot
  # 
  # The Sunspot::Util module provides utility methods used elsewhere in the
  # library.
  #
  module Util #:nodoc:
    # TODO no longer needed after refactor
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
      # 
      # Get all of the superclasses for a given class, including the class
      # itself.
      # 
      # ==== Parameters
      #
      # clazz<Class>:: class for which to get superclasses
      #
      # ==== Returns
      #
      # Array:: Collection containing class and its superclasses
      #
      def superclasses_for(clazz)
        superclasses = [clazz]
        superclasses << (clazz = clazz.superclass) while clazz.superclass != Object
        superclasses
      end

      # 
      # Perform a deep merge of hashes, returning the result as a new hash.
      # See #deep_merge_into for rules used to merge the hashes
      #
      # ==== Parameters
      #
      # left<Hash>:: Hash to merge
      # right<Hash>:: The other hash to merge
      #
      # ==== Returns
      #
      # Hash:: New hash containing the given hashes deep-merged.
      #
      def deep_merge(left, right)
        deep_merge_into({}, left, right)
      end

      # 
      # Perform a deep merge of the right hash into the left hash
      #
      # ==== Parameters
      #
      # left:: Hash to receive merge
      # right:: Hash to merge into left
      #
      # ==== Returns
      #
      # Hash:: left
      #
      def deep_merge!(left, right)
        deep_merge_into(left, left, right)
      end

      private

      # 
      # Deep merge two hashes into a third hash, using rules that produce nice
      # merged parameter hashes. The rules are as follows, for a given key:
      #
      # * If only one hash has a value, or if both hashes have the same value,
      #   just use the value.
      # * If either of the values is not a hash, create arrays out of both
      #   values and concatenate them.
      # * Otherwise, deep merge the two values (which are both hashes)
      #
      # ==== Parameters
      #
      # destination<Hash>:: Hash into which to perform the merge
      # left<Hash>:: One hash to merge
      # right<Hash>:: The other hash to merge
      #
      # ==== Returns
      #
      # Hash:: destination
      #
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
