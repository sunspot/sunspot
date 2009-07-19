module Sunspot
  # 
  # This class presents a service for adding, updating, and removing data
  # from the Solr index. An Indexer instance is associated with a particular
  # setup, and thus is capable of indexing instances of a certain class (and its
  # subclasses).
  #
  class Indexer #:nodoc:
    include RSolr::Char

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
      documents = Array(model).map { |m| prepare(m) }
      if @batch.nil?
        add_documents(documents)
      else
        @batch.concat(documents)
      end
    end

    # 
    # Remove the given model from the Solr index
    #
    def remove(model)
      @connection.delete_by_id(Adapters::InstanceAdapter.adapt(model).index_id)
    end

    def remove_by_id(class_name, id)
      @connection.delete_by_id(
        Adapters::InstanceAdapter.index_id_for(class_name, id)
      )
    end

    # 
    # Delete all documents of the class indexed by this indexer from Solr.
    #
    def remove_all(clazz)
      @connection.delete_by_query("type:#{escape(clazz.name)}")
    end

    def start_batch
      @batch = []
    end

    def flush_batch
      add_documents(@batch)
      @batch = nil
    end

    private

    # 
    # Convert documents into hash of indexed properties
    #
    def prepare(model)
      document = document_for(model)
      setup = setup_for(model)
      if boost = setup.document_boost_for(model)
        document.attrs[:boost] = boost
      end
      for field_factory in setup.all_field_factories
        field_factory.populate_document(document, model)
      end
      document
    end

    def add_documents(documents)
      @connection.add(documents)
    end

    # 
    # All indexed documents index and store the +id+ and +type+ fields.
    # This method constructs the document hash containing those key-value
    # pairs.
    #
    def document_for(model)
      RSolr::Message::Document.new(
        :id => Adapters::InstanceAdapter.adapt(model).index_id,
        :type => Util.superclasses_for(model.class).map { |clazz| clazz.name }
      )
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
    def setup_for(object)
      Setup.for(object.class) || raise(NoSetupError, "Sunspot is not configured for #{object.class.inspect}")
    end


    class <<self
      # 
      # Delete all documents from the Solr index
      #
      # ==== Parameters
      #
      # connection<Solr::Connection>::
      #   connection to which to send the delete request
      def remove_all(connection)
        connection.delete_by_query("type:[* TO *]")
      end
    end
  end
end
