module Sunspot
  #
  # Sunspot works by saving references to the primary key (or natural ID) of
  # each indexed object, and then retrieving the objects from persistent storage
  # when their IDs are referenced in search results. In order for Sunspot to
  # know what an object's primary key is, and how to retrieve objects from
  # persistent storage given a primary key, an adapter must be registered for
  # that object's class or one of its superclasses (for instance, an adapter
  # registered for ActiveRecord::Base would be used for all ActiveRecord
  # models).
  #
  # To provide Sunspot with this ability, adapters must have two roles:
  #
  # Data accessor::
  #   A subclass of Sunspot::Adapters::DataAccessor, this object is instantiated
  #   with a particular class and must respond to the #load() method, which
  #   returns an object from persistent storage given that object's primary key.
  #   It can also optionally implement the #load_all() method, which returns
  #   a collection of objects given a collection of primary keys, if that can be
  #   done more efficiently than calling #load() on each key.
  # Instance adapter::
  #   A subclass of Sunspot::Adapters::InstanceAdapter, this object is
  #   instantiated with a particular instance. Its only job is to tell Sunspot
  #   what the object's primary key is, by implementing the #id() method.
  #
  # Adapters are registered by registering their two components, telling Sunspot
  # that they are available for one or more classes, and all of their
  # subclasses. See Sunspot::Adapters::DataAccessor.register and
  # Sunspot::Adapters::InstanceAdapter.register for the details.
  #
  # See spec/mocks/mock_adapter.rb for an example of how adapter classes should
  # be implemented.
  #
  module Adapters
    # Subclasses of the InstanceAdapter class should implement the #id method,
    # which returns the primary key of the instance stored in the @instance
    # variable. The primary key must be unique within the scope of the
    # instance's class.
    #
    # ==== Example:
    #
    #   class FileAdapter < Sunspot::Adapters::InstanceAdapter
    #     def id
    #       File.expand_path(@instance.path)
    #     end
    #   end
    #
    #   # then in your initializer
    #   Sunspot::Adapters::InstanceAdapter.register(MyAdapter, File)
    #
    class InstanceAdapter
      def initialize(instance) #:nodoc:
        @instance = instance
      end

      #
      # The universally-unique ID for this instance that will be stored in solr
      #
      # ==== Returns
      #
      # String:: ID for use in Solr
      #
      def index_id #:nodoc:
        InstanceAdapter.index_id_for(@instance.class.name, id)
      end

      class <<self
        # Instantiate an InstanceAdapter for the given object, searching for
        # registered adapters for the object's class.
        #
        # ==== Parameters
        #
        # instance<Object>:: The instance to adapt
        #
        # ==== Returns
        #
        # InstanceAdapter::
        #   An instance of an InstanceAdapter implementation that
        #   wraps the given instance
        #
        def adapt(instance) #:nodoc:
          @known_adapters ||= {}
          clazz = instance.class
          adapter = @known_adapters[clazz.name.to_sym] || self.for(clazz)
          @known_adapters[clazz.name.to_sym] ||= adapter
          adapter.new(instance)
        end

        # Register an instance adapter for a set of classes. When searching for
        # an adapter for a given instance, Sunspot starts with the instance's
        # class, and then searches for registered adapters up the class's
        # ancestor chain.
        #
        # ==== Parameters
        #
        # instance_adapter<Class>:: The instance adapter class to register
        # classes...<Class>::
        #   One or more classes that this instance adapter adapts
        #
        def register(instance_adapter, *classes)
          classes.each do |clazz|
            instance_adapters[clazz.name.to_sym] = instance_adapter
          end
        end

        # Find the best InstanceAdapter implementation that adapts the given
        # class.  Starting with the class and then moving up the ancestor chain,
        # looks for registered InstanceAdapter implementations.
        #
        # ==== Parameters
        #
        # clazz<Class>:: The class to find an InstanceAdapter for
        #
        # ==== Returns
        #
        # Class:: Subclass of InstanceAdapter, or nil if none found
        #
        # ==== Raises
        #
        # Sunspot::NoAdapterError:: If no adapter is registered for this class
        #
        def for(clazz) #:nodoc:
          original_class_name = clazz.name
          clazz.ancestors.each do |ancestor_class|
            next if ancestor_class.name.nil? || ancestor_class.name.empty?
            class_name = ancestor_class.name.to_sym
            return instance_adapters[class_name] if instance_adapters[class_name]
          end

          raise(Sunspot::NoAdapterError,
                "No adapter is configured for #{original_class_name} or its superclasses. See the documentation for Sunspot::Adapters")
        end

        def index_id_for(class_name, id) #:nodoc:
          "#{class_name} #{id}"
        end

        protected

        # Lazy-initialize the hash of registered instance adapters
        #
        # ==== Returns
        #
        # Hash:: Hash containing class names keyed to instance adapter classes
        #
        def instance_adapters #:nodoc:
          @instance_adapters ||= {}
        end
      end
    end

    # Subclasses of the DataAccessor class take care of retrieving instances of
    # the adapted class from (usually persistent) storage. Subclasses must
    # implement the #load method, which takes an id (the value returned by
    # InstanceAdapter#id, as a string), and returns the instance referenced by
    # that ID. Optionally, it can also override the #load_all method, which
    # takes an array of IDs and returns an array of instances in the order
    # given. #load_all need only be implemented if it can be done more
    # efficiently than simply iterating over the IDs and calling #load on each
    # individually.
    #
    # ==== Example
    #
    #   class FileAccessor < Sunspot::Adapters::InstanceAdapter
    #     def load(id)
    #       @clazz.open(id)
    #     end
    #   end
    #
    #   Sunspot::Adapters::DataAccessor.register(FileAccessor, File)
    #
    class DataAccessor
      # Attributes that should be passed to other adapted subclasses
      attr_accessor :inherited_attributes
      attr_reader :clazz

      def initialize(clazz) #:nodoc:
        @clazz = clazz
        @inherited_attributes = []
      end

      # Subclasses can override this class to provide more efficient bulk
      # loading of instances. Instances must be returned in the same order
      # that the IDs were given.
      #
      # ==== Parameters
      #
      # ids<Array>:: collection of IDs
      #
      # ==== Returns
      #
      # Array:: collection of instances, in order of IDs given
      #
      def load_all(ids)
        ids.map { |id| self.load(id) }
      end

      class <<self
        # Create a DataAccessor for the given class, searching registered
        # adapters for the best match. See InstanceAdapter#adapt for discussion
        # of inheritance.
        #
        # ==== Parameters
        #
        # clazz<Class>:: Class to create DataAccessor for
        #
        # ==== Returns
        #
        # DataAccessor::
        #   DataAccessor implementation which provides access to given class
        #
        def create(clazz) #:nodoc:
          self.for(clazz).new(clazz)
        end

        # Register data accessor for a set of classes. When searching for
        # an accessor for a given class, Sunspot starts with the class,
        # and then searches for registered adapters up the class's ancestor
        # chain.
        #
        # ==== Parameters
        #
        # data_accessor<Class>:: The data accessor class to register
        # classes...<Class>::
        #   One or more classes that this data accessor provides access to
        #
        def register(data_accessor, *classes)
          classes.each do |clazz|
            data_accessors[clazz.name.to_sym] = data_accessor
          end
        end

        # Find the best DataAccessor implementation that adapts the given class.
        # Starting with the class and then moving up the ancestor chain, looks
        # for registered DataAccessor implementations.
        #
        # ==== Parameters
        #
        # clazz<Class>:: The class to find a DataAccessor for
        #
        # ==== Returns
        #
        # Class:: Implementation of DataAccessor
        #
        # ==== Raises
        #
        # Sunspot::NoAdapterError:: If no data accessor exists for the given class
        #
        def for(clazz) #:nodoc:
          original_class_name = clazz.name
          clazz.ancestors.each do |ancestor_class|
            next if ancestor_class.name.nil? || ancestor_class.name.empty?
            class_name = ancestor_class.name.to_sym
            return data_accessors[class_name] if data_accessors[class_name]
          end
          raise(Sunspot::NoAdapterError,
                "No data accessor is configured for #{original_class_name} or its superclasses. See the documentation for Sunspot::Adapters")
        end

        protected

        # Lazy-initialize the hash of registered data accessors
        #
        # ==== Returns
        #
        # Hash:: Hash containing class names keyed to data accessor classes
        #
        def data_accessors #:nodoc:
          @adapters ||= {}
        end
      end
    end

    # Allows to have a registry of the classes adapted by a DataAccessor. This
    # registry does the class registration using DataAccessor's #create and while
    # doing so also allows a registered class to notify which attributes
    # should be inherited by its subclasses. 
    # This is useful in cases such us ActiveRecord's #include option, where 
    # you may need to run a search in all the subclasses of a searchable model 
    # and including some associations for all of them when it loads.
    #
    # ==== Example
    #
    # # ActiveRecordDataAccessor marks :include and :select as inherited_attributes
    # class ActiveRecordDataAccessor < Sunspot::Adapters::DataAccessor
    #   # options for the find
    #   attr_accessor :include, :select
    #
    #   def initialize(clazz)
    #     super(clazz)
    #     @inherited_attributes = [:include, :select]
    #   end
    # end
    #
    # class Event < ActiveRecord::Base
    #   searchable do
    #    #stuff here
    #   end
    # end
    # class Play < Event ; end
    # class Movie < Event ; end
    #
    # # This will push the :include to ALL of the Event's subclasses
    # @search = Event.search(include: [:images])
    #
    # # You can also set the value just one class's attribute
    # @search.data_accessor_for(Play).include = [ :images, :location]
    #
    class Registry
      extend Forwardable

      def initialize
        @reg = {}
      end
      def_delegator :@reg, :keys, :registered
      def_delegators :@reg, :include?

      def retrieve(clazz)
        key = clazz.name.to_sym
        if !@reg.include?(key)
          data_accessor = inject_inherited_attributes_for( Adapters::DataAccessor.create(clazz) )
          @reg[key] ||= data_accessor
        end
        @reg[key]
      end

      # It will inject declared attributes to be inherited from ancestors
      # only if they are not already present in the data_accessor for each class.
      def inject_inherited_attributes_for(data_accessor)
        return data_accessor if @reg.empty?

        data_accessor.inherited_attributes.each do |attribute|
          if data_accessor.send(attribute).nil? # Inject only if the current class didn't define one.
            inherited_value = nil
            # Now try to find a value for the attribute in the chain of ancestors
            data_accessor.clazz.ancestors.each do |ancestor|
              next if ancestor.name.nil? || ancestor.name.empty?
              key = ancestor.name.to_sym
              inherited_value = @reg[key].send(attribute) if @reg[key]
              break unless inherited_value.nil?
            end
            data_accessor.send("#{attribute.to_s}=", inherited_value) unless inherited_value.nil?
          end
        end
        data_accessor
      end
    end
  end
end
