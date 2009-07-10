module Sunspot
  module DSL #:nodoc:
    # The Fields class provides a DSL for specifying field definitions in the
    # Sunspot.setup block. As well as the #text method, which creates fulltext
    # fields, uses #method_missing to allow definition of typed fields. The
    # available methods are determined by the constants defined in 
    # Sunspot::Type - in theory (though this is untested), plugin developers
    # should be able to add support for new types simply by creating new
    # implementations in Sunspot::Type
    #
    class Fields
      def initialize(setup) #:nodoc:
        @setup = setup
      end

      # Add a text field. Text fields are tokenized before indexing and are
      # the only fields searched in fulltext searches. If a block is passed,
      # create a virtual field; otherwise create an attribute field.
      #
      # ==== Parameters
      #
      # names...<Symbol>:: One or more field names
      #
      def text(*names, &block)
        options = names.pop if names.last.is_a?(Hash)
        for name in names
          @setup.add_text_field_factories(
            FieldFactory::Static.new(
              name,
              Type::TextType,
              options || {},
              &block
            )
          )
        end
      end

      # method_missing is used to provide access to typed fields, because
      # developers should be able to add new Sunspot::Type implementations
      # dynamically and have them recognized inside the Fields DSL. Like #text,
      # these methods will create a VirtualField if a block is passed, or an
      # AttributeField if not.
      #
      # ==== Example
      #
      #   Sunspot.setup(File) do
      #     time :mtime
      #   end
      #
      # The call to +time+ will create a field of type Sunspot::Types::TimeType
      #
      def method_missing(method, *args, &block)
        begin
          type = Type.const_get("#{Util.camel_case(method.to_s.sub(/^dynamic_/, ''))}Type")
        rescue(NameError)
          super(method.to_sym, *args, &block) and return
        end
        name = args.shift
        if method.to_s =~ /^dynamic_/
          @setup.add_dynamic_field_factories(FieldFactory::Dynamic.new(name, type, *args, &block))
        else
          @setup.add_field_factories(FieldFactory::Static.new(name, type, *args, &block))
        end
      end
    end
  end
end
