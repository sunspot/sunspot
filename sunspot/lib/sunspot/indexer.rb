require 'sunspot/batcher'

module Sunspot
  # 
  # This class presents a service for adding, updating, and removing data
  # from the Solr index. An Indexer instance is associated with a particular
  # setup, and thus is capable of indexing instances of a certain class (and its
  # subclasses).
  #
  class Indexer #:nodoc:

    def initialize(connection)
      @connection = connection
    end

    # 
    # Construct a representation of the model for indexing and send it to the
    # connection for indexing
    #
    # ==== Parameters
    #
    # model<Object>:: the model to index
    #
    def add(model)
      documents = Util.Array(model).map { |m| prepare_full_update(m) }
      add_batch_documents(documents)
    end

    #
    # Construct a representation of the given class instances for atomic properties update
    # and send it to the connection for indexing
    #
    # ==== Parameters
    #
    # clazz<Class>:: the class of the models to be updated
    # updates<Hash>:: hash of updates where keys are model ids
    #                 and values are hash with property name/values to be updated
    #
    def add_atomic_update(clazz, updates={})
      documents = updates.map { |id, m| prepare_atomic_update(clazz, id, m) }
      add_batch_documents(documents)
    end

    # 
    # Remove the given model from the Solr index
    #
    def remove(*models)
      @connection.delete_by_id(
        models.map { |model| Adapters::InstanceAdapter.adapt(model).index_id }
      )
    end

    # 
    # Remove the model from the Solr index by specifying the class and ID
    #
    def remove_by_id(class_name, *ids)
      ids.flatten!
      @connection.delete_by_id(
        ids.map { |id| Adapters::InstanceAdapter.index_id_for(class_name, id) }
      )
    end

    #
    # Delete all documents of the class indexed by this indexer from Solr.
    #
    def remove_all(clazz = nil)
      if clazz
        @connection.delete_by_query("type:#{Util.escape(clazz.name)}")
      else
        @connection.delete_by_query("*:*")
      end
    end

    # 
    # Remove all documents that match the scope given in the Query
    #
    def remove_by_scope(scope)
      @connection.delete_by_query(scope.to_boolean_phrase)
    end

    # 
    # Start batch processing
    #
    def start_batch
      batcher.start_new
    end

    #
    # Write batch out to Solr and clear it
    #
    def flush_batch
      add_documents(batcher.end_current)
    end

    private

    def batcher
      @batcher ||= Batcher.new
    end

    # 
    # Convert documents into hash of indexed properties
    #
    def prepare_full_update(model)
      document = document_for_full_update(model)
      setup = setup_for_object(model)
      if boost = setup.document_boost_for(model)
        document.attrs[:boost] = boost
      end
      setup.all_field_factories.each do |field_factory|
        field_factory.populate_document(document, model)
      end
      document
    end

    def prepare_atomic_update(clazz, id, updates = {})
      document = document_for_atomic_update(clazz, id)
      setup_for_class(clazz).all_field_factories.each do |field_factory|
        if updates.has_key?(field_factory.name)
          field_factory.populate_document(document, nil, value: updates[field_factory.name], update: :set)
        end
      end
      document
    end

    def add_documents(documents)
      @connection.add(documents)
    end

    def add_batch_documents(documents)
      if batcher.batching?
        batcher.concat(documents)
      else
        add_documents(documents)
      end
    end

    # 
    # All indexed documents index and store the +id+ and +type+ fields.
    # These methods construct the document hash containing those key-value
    # pairs.
    #
    def document_for_full_update(model)
      RSolr::Xml::Document.new(
        id: Adapters::InstanceAdapter.adapt(model).index_id,
        type: Util.superclasses_for(model.class).map(&:name)
      )
    end

    def document_for_atomic_update(clazz, id)
      if Adapters::InstanceAdapter.for(clazz)
        RSolr::Xml::Document.new(
            id: Adapters::InstanceAdapter.index_id_for(clazz.name, id),
            type: Util.superclasses_for(clazz).map(&:name)
        )
      end
    end
    # 
    # Get the Setup object for the given object's class.
    #
    # ==== Parameters
    #
    # object<Object>:: The object whose setup is to be retrieved
    #
    # ==== Returns
    #
    # Sunspot::Setup:: The setup for the object's class
    #
    def setup_for_object(object)
      setup_for_class(object.class)
    end

    #
    # Get the Setup object for the given class.
    #
    # ==== Parameters
    #
    # clazz<Class>:: The class whose setup is to be retrieved
    #
    # ==== Returns
    #
    # Sunspot::Setup:: The setup for the class
    #
    def setup_for_class(clazz)
      Setup.for(clazz) || raise(NoSetupError, "Sunspot is not configured for #{clazz.inspect}")
    end
  end
end
