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
      #   Index-time boost that should be applied to this field for keyword search
      # :default_boost<Float>::
      #   Default search-time boost to apply to this field during keyword
      #   search. Can be overriden with DSL::Fulltext#fields or
      #   DSL::Fulltext#boost_fields method.
      #
      def text(*names, &block)
        options = names.pop if names.last.is_a?(Hash)
        names.each do |name|
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
        options = Util.extract_options_from(args)
        type_const_name = "#{Util.camel_case(method.to_s.sub(/^dynamic_/, ''))}Type"
        trie = options.delete(:trie)
        type_const_name = "Trie#{type_const_name}" if trie
        begin
          type_class = Type.const_get(type_const_name)
        rescue(NameError)
          if trie
            raise ArgumentError, "Trie fields are only valid for numeric and time types"
          else
            super(method, *args, &block)
          end
        end
        type = type_class.instance
        name = args.shift
        if method.to_s =~ /^dynamic_/
          if type.accepts_dynamic?
            @setup.add_dynamic_field_factory(name, type, options, &block)
          else
            super(method, *args, &block)
          end
        else
          @setup.add_field_factory(name, type, options, &block)
        end
      end
    end
  end
end
