module Sunspot
  # 
  # This class encapsulates the search/indexing setup for a given class. Its
  # contents are built using the Sunspot.setup method.
  #
  class Setup #:nodoc:
    def initialize(clazz)
      @clazz = clazz
      @class_name = clazz.name
      @field_factories, @text_field_factories, @dynamic_field_factories,
        @field_factories_cache, @text_field_factories_cache,
        @dynamic_field_factories_cache = *Array.new(6) { Hash.new }
      @stored_field_factories_cache = Hash.new { |h, k| h[k] = [] }
      @dsl = DSL::Fields.new(self)
      add_field_factory(:class, Type::ClassType)
    end

    def type_names
      [@class_name]
    end

    # 
    # Add field factory for scope/ordering
    #
    def add_field_factory(name, type, options = {}, &block)
      stored = options[:stored]
      field_factory = FieldFactory::Static.new(name, type, options, &block)
      @field_factories[field_factory.signature] = field_factory
      @field_factories_cache[field_factory.name] = field_factory
      if stored
        @stored_field_factories_cache[field_factory.name] << field_factory
      end
    end

    # 
    # Add field_factories for fulltext search
    #
    # ==== Parameters
    #
    # field_factories<Array>:: Array of Sunspot::Field objects
    #
    def add_text_field_factory(name, options = {}, &block)
      stored = options[:stored]
      field_factory = FieldFactory::Static.new(name, Type::TextType, options, &block)
      @text_field_factories[name] = field_factory
      @text_field_factories_cache[field_factory.name] = field_factory
      if stored
        @stored_field_factories_cache[field_factory.name] << field_factory
      end
    end

    #
    # Add dynamic field_factories
    #
    # ==== Parameters
    # 
    # field_factories<Array>:: Array of dynamic field objects
    # 
    def add_dynamic_field_factory(name, type, options = {}, &block)
      field_factory = FieldFactory::Dynamic.new(name, type, options, &block)
      @dynamic_field_factories[field_factory.signature] = field_factory
      @dynamic_field_factories_cache[field_factory.name] = field_factory
    end

    # 
    # The coordinates field factory is used for populating the coordinate fields
    # of documents during index, but does not actually generate fields (since
    # the field names used in search are static).
    #
    def set_coordinates_field(name = nil, &block)
      @coordinates_field_factory = FieldFactory::Coordinates.new(name, &block)
    end

    # 
    # Add a document boost to documents at index time. Document boost can be
    # static (the same for all documents of this class), or extracted on a per-
    # document basis using either attribute or block extraction as per usual.
    #
    def add_document_boost(attr_name, &block)
      @document_boost_extractor =
        if attr_name
          if attr_name.respond_to?(:to_f)
            DataExtractor::Constant.new(attr_name)
          else
            DataExtractor::AttributeExtractor.new(attr_name)
          end
        else
          DataExtractor::BlockExtractor.new(&block)
        end
    end

    # 
    # Builder method for evaluating the setup DSL
    #
    def setup(&block)
      @dsl.instance_eval(&block)
    end

    # 
    # Return the Field with the given (public-facing) name
    #
    def field(field_name)
      if field_factory = @field_factories_cache[field_name.to_sym]
        field_factory.build
      else
        raise(
          UnrecognizedFieldError,
          "No field configured for #{@clazz.name} with name '#{field_name}'"
        )
      end
    end

    # 
    # Return one or more text fields with the given public-facing name. This
    # implementation will always return a single field (in an array), but
    # CompositeSetup objects might return more than one.
    #
    def text_fields(field_name)
      text_field = 
        if field_factory = @text_field_factories_cache[field_name.to_sym]
          field_factory.build
        else
          raise(
            UnrecognizedFieldError,
            "No text field configured for #{@clazz.name} with name '#{field_name}'"
          )
        end
      [text_field]
    end

    #
    # Return one or more stored fields (can be either attribute or text fields)
    # for the given name.
    #
    def stored_fields(field_name)
      @stored_field_factories_cache[field_name.to_sym].map do |field_factory|
        field_factory.build
      end
    end

    # 
    # Return the DynamicFieldFactory with the given base name
    #
    def dynamic_field_factory(field_name)
      @dynamic_field_factories_cache[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No dynamic field configured for #{@clazz.name} with name '#{field_name}'"
      )
    end

    # 
    # Return all attribute fields
    #
    def fields
      field_factories.map { |field_factory| field_factory.build }
    end

    # 
    # Return all text fields
    #
    def all_text_fields
      text_field_factories.map { |text_field_factory| text_field_factory.build }
    end

    # 
    # Get the field_factories associated with this setup as well as all inherited field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all field_factories associated with this setup
    #
    def field_factories
      collection_from_inheritable_hash(:field_factories)
    end

    # 
    # Get the text field_factories associated with this setup as well as all inherited
    # text field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all text field_factories associated with this setup
    #
    def text_field_factories
      collection_from_inheritable_hash(:text_field_factories)
    end

    # 
    # Get all static, dynamic, and text field_factories associated with this setup as
    # well as all inherited field_factories
    #
    # ==== Returns
    #
    # Array:: Collection of all text and scope field_factories associated with this setup
    #
    def all_field_factories
      all_field_factories = []
      all_field_factories.concat(field_factories).concat(text_field_factories).concat(dynamic_field_factories)
      all_field_factories << @coordinates_field_factory if @coordinates_field_factory
      all_field_factories
    end

    # 
    # Get all dynamic field_factories for this and parent setups
    # 
    # ==== Returns
    #
    # Array:: Dynamic field_factories
    #
    def dynamic_field_factories
      collection_from_inheritable_hash(:dynamic_field_factories)
    end

    # 
    # Return the class associated with this setup.
    #
    # ==== Returns
    #
    # clazz<Class>:: Class setup is configured for
    #
    def clazz
      Util.full_const_get(@class_name)
    end

    # 
    # Get the document boost for a given model
    #
    def document_boost_for(model)
      if @document_boost_extractor
        @document_boost_extractor.value_for(model)
      end
    end

    protected

    # 
    # Get the nearest inherited setup, if any
    #
    # ==== Returns
    # 
    # Sunspot::Setup:: Setup for the nearest ancestor of this setup's class
    #
    def parent
      Setup.for(clazz.superclass)
    end

    def get_inheritable_hash(name)
      hash = instance_variable_get(:"@#{name}")
      parent.get_inheritable_hash(name).each_pair do |key, value|
        hash[key] = value unless hash.has_key?(key)
      end if parent
      hash
    end

    private

    def collection_from_inheritable_hash(name)
      get_inheritable_hash(name).values
    end

    class <<self
      # 
      # Retrieve or create the Setup instance for the given class, evaluating
      # the given block to add to the setup's configuration
      #
      def setup(clazz, &block) #:nodoc:
        self.for!(clazz).setup(&block)
      end

      # 
      # Retrieve the setup instance for the given class, or for the nearest
      # ancestor that has a setup, if any.
      #
      # ==== Parameters
      #
      # clazz<Class>:: Class for which to retrieve a setup
      #
      # ==== Returns
      #
      # Sunspot::Setup::
      #   Setup instance associated with the given class or its nearest ancestor
      #   
      def for(clazz) #:nodoc:
        class_name =
          if clazz.respond_to?(:name)
            clazz.name
          else
            clazz
          end
        setups[class_name.to_sym] || self.for(clazz.superclass) if clazz
      end

      protected

      # 
      # Retrieve or create a Setup instance for this class
      #
      # ==== Parameters
      #
      # clazz<Class>:: Class for which to retrieve a setup
      #
      # ==== Returns
      #
      # Sunspot::Setup:: New or existing setup for this class
      #
      def for!(clazz) #:nodoc:
        setups[clazz.name.to_sym] ||= new(clazz)
      end

      private

      # Singleton hash of class names to Setup instances
      #
      # ==== Returns
      #
      # Hash:: Class names keyed to Setup instances
      #
      def setups
        @setups ||= {}
      end
    end
  end
end
