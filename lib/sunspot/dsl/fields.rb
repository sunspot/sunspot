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
      # If options are passed, they will be applied to all the given fields.
      #
      # ==== Parameters
      #
      # names...<Symbol>:: One or more field names
      #
      # ==== Options
      #
      # :boost<Float>::
      #   Boost that should be applied to this field for keyword search
      #
      def text(*names, &block)
        options = names.pop if names.last.is_a?(Hash)
        for name in names
          @setup.add_text_field_factory(
            name,
            options || {},
            &block
          )
        end
      end

      # 
      # Specify a document-level boost. As with fields, you have the option of
      # passing an attribute name which will be called on each model, or a block
      # to be evaluated in the model's context. As well as these two options,
      # this method can also take a constant number, meaning that all indexed
      # documents of this class will have the specified boost.
      #
      # ==== Parameters
      #
      # attr_name<Symbol,~.to_f>:: Attribute name to call or a numeric constant
      #
      def boost(attr_name = nil, &block)
        @setup.add_document_boost(attr_name, &block)
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
          @setup.add_dynamic_field_factory(name, type, *args, &block)
        else
          @setup.add_field_factory(name, type, *args, &block)
        end
      end
    end
  end
end
