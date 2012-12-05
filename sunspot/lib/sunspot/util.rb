module Sunspot
  # 
  # The Sunspot::Util module provides utility methods used elsewhere in the
  # library.
  #
  module Util #:nodoc:
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
      # Convert a string to snake case
      #
      # ==== Parameters
      #
      # string<String>:: String to convert to snake case
      #
      # ==== Returns
      #
      # String:: String in snake case
      #
      def snake_case(string)
        string.scan(/(^|[A-Z])([^A-Z]+)/).map! { |word| word.join.downcase }.join('_')
      end

      # 
      # Convert a string to camel case
      #
      # ==== Parameters
      #
      # string<String>:: String to convert to camel case
      #
      # ==== Returns
      #
      # String:: String in camel case
      #
      def camel_case(string)
        string.split('_').map! { |word| word.capitalize }.join
      end

      # 
      # Get a constant from a fully qualified name
      #
      # ==== Parameters
      #
      # string<String>:: The fully qualified name of a constant
      #
      # ==== Returns
      #
      # Object:: Value of constant named
      #
      def full_const_get(string)
        string.split('::').inject(Object) do |context, const_name|
          context.const_defined?(const_name) ? context.const_get(const_name) : context.const_missing(const_name)
        end
      end

      # 
      # Evaluate the given proc in the context of the given object if the
      # block's arity is non-positive, or by passing the given object as an
      # argument if it is negative.
      # 
      # ==== Parameters
      # 
      # object<Object>:: Object to pass to the proc
      #
      def instance_eval_or_call(object, &block)
        if block.arity > 0
          block.call(object)
        else
          ContextBoundDelegate.instance_eval_with_context(object, &block)
        end
      end

      def extract_options_from(args)
        if args.last.is_a?(Hash)
          args.pop
        else
          {}
        end
      end

      #
      # Ruby's treatment of Strings as Enumerables is heavily annoying. As far
      # as I know the behavior of Kernel.Array() is otherwise fine.
      #
      def Array(object)
        case object
        when String, Hash
          [object]
        else
          super
        end
      end

      # 
      # When generating boosts, Solr requires that the values be in standard
      # (not scientific) notation. We would like to ensure a minimum number of
      # significant digits (i.e., digits that are not prefix zeros) for small
      # float values.
      #
      def format_float(f, digits)
        if f < 1
          sprintf('%.*f', digits - Math.log10(f), f)
        else
          f.to_s
        end
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
          right_value = right[name] if right
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

    Coordinates = Struct.new(:lat, :lng)

    class ContextBoundDelegate
      class <<self
        def instance_eval_with_context(receiver, &block)
          calling_context = eval('self', block.binding)
          if parent_calling_context = calling_context.instance_eval{@__calling_context__ if defined?(@__calling_context__)}
            calling_context = parent_calling_context
          end
          new(receiver, calling_context).instance_eval(&block)
        end
        private :new
      end

      BASIC_METHODS = Set[:==, :equal?, :"!", :"!=", :instance_eval,
                          :object_id, :__send__, :__id__]

      instance_methods.each do |method|
        unless BASIC_METHODS.include?(method.to_sym)
          undef_method(method)
        end
      end

      def initialize(receiver, calling_context)
        @__receiver__, @__calling_context__ = receiver, calling_context
      end

      def id
        @__calling_context__.__send__(:id)
      end

      # Special case due to `Kernel#sub`'s existence
      def sub(*args, &block)
        __proxy_method__(:sub, *args, &block)
      end

      def method_missing(method, *args, &block)
        __proxy_method__(method, *args, &block)
      end

      def __proxy_method__(method, *args, &block)
        begin
          @__receiver__.__send__(method.to_sym, *args, &block)
        rescue ::NoMethodError => e
          begin
            @__calling_context__.__send__(method.to_sym, *args, &block)
          rescue ::NoMethodError
            raise(e)
          end
        end
      end
    end
  end
end
