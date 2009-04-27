module Sunspot
  # Sunspot provides an adapter architecture that allows applications or plugin
  # developers to define adapters for any type of object. An adapter is composed
  # of two classes, an InstanceAdapter and a DataAccessor. Note that an adapter
  # does not need to provide both classes - InstanceAdapter is only needed if
  # you wish to index instances of the class, and DataAccessor is only needed if
  # you wish to retrieve instances of this class in search results. Of course,
  # both will be the case most of the time.
  #
  # See Sunspot::Adapters::DataAccessor.register and
  # Sunspot::Adapters::InstanceAdapter.register for information on how to enable
  # an adapter for use by Sunspot.
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
        "#{@instance.class.name} #{id}"
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
          self.for(instance.class).new(instance)
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
          for clazz in classes
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
        def for(clazz) #:nodoc:
          while clazz != Object
            class_name = clazz.name.to_sym
            return instance_adapters[class_name] if instance_adapters[class_name]
            clazz = clazz.superclass
          end
          nil
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

    # Subclasses of the DataAccessor class take care of retreiving instances of
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
      def initialize(clazz) #:nodoc:
        @clazz = clazz
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
        # of inheritence.
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
        def create(clazz)
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
        #   One or more classes that this data accessor providess access to
        #
        def register(data_accessor, *classes)
          for clazz in classes
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
        # Class:: Implementation of DataAccessor, or nil if none found
        #
        def for(clazz) #:nodoc:
          while clazz != Object
            class_name = clazz.name.to_sym
            return data_accessors[class_name] if data_accessors[class_name]
            clazz = clazz.superclass
          end
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
  end
end
