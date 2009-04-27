module Sunspot
  # 
  # This class encapsulates the search/indexing setup for a given class. Its
  # contents are built using the Sunspot.setup method.
  #
  class Setup #:nodoc:
    def initialize(clazz)
      @class_name = clazz.name
      @fields, @text_fields = [], []
      @dsl = DSL::Fields.new(self)
    end

    # 
    # Add fields for scope/ordering
    # 
    # ==== Parameters
    #
    # fields<Array>:: Array of Sunspot::Field objects
    #
    def add_fields(fields)
      @fields.concat(Array(fields))
    end

    # 
    # Add fields for fulltext search
    #
    # ==== Parameters
    #
    # fields<Array>:: Array of Sunspot::Field objects
    #
    def add_text_fields(fields)
      @text_fields.concat(Array(fields))
    end

    # 
    # Builder method for evaluating the setup DSL
    #
    def setup(&block)
      @dsl.instance_eval(&block)
    end

    # 
    # Get the fields associated with this setup as well as all inherited fields
    #
    # ==== Returns
    #
    # Array:: Collection of all fields associated with this setup
    #
    def fields
      fields = @fields.dup
      fields.concat(parent.fields) if parent
      fields
    end

    # 
    # Get the text fields associated with this setup as well as all inherited
    # text fields
    #
    # ==== Returns
    #
    # Array:: Collection of all text fields associated with this setup
    #
    def text_fields
      text_fields = @text_fields.dup
      text_fields.concat(parent.text_fields) if parent
      text_fields
    end

    # 
    # Get all scope and text fields associated with this setup as well as all
    # inherited fields
    #
    # ==== Returns
    #
    # Array:: Collection of all text and scope fields associated with this setup
    #
    def all_fields
      fields + text_fields
    end

    # 
    # Factory method for an Indexer object configured to use this setup
    #
    # ==== Returns
    #
    # Sunspot::Indexer:: Indexer configured with this setup
    def indexer(connection)
      Indexer.new(connection, self)
    end

    # 
    # Return the class associated with this setup.
    #
    # ==== Returns
    #
    # clazz<Class>:: Class setup is configured for
    #
    def clazz
      Object.full_const_get(@class_name)
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
        setups[clazz.name] || self.for(clazz.superclass) if clazz
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
        setups[clazz.name] ||= new(clazz)
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
