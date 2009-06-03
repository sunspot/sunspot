module Sunspot
  # 
  # This class presents a service for adding, updating, and removing data
  # from the Solr index. An Indexer instance is associated with a particular
  # setup, and thus is capable of indexing instances of a certain class (and its
  # subclasses).
  #
  class Indexer #:nodoc:
    def initialize(connection, setup)
      @connection, @setup = connection, setup
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
      if model.is_a?(Array)
        docs = model.map { |m| prepare(m) }
      else
        docs = [prepare(model)]
      end
      @connection.add(docs)
    end

    # 
    # Remove the given model from the Solr index
    #
    def remove(model)
      @connection.delete(Adapters::InstanceAdapter.adapt(model).index_id)
    end

    # 
    # Delete all documents of the class indexed by this indexer from Solr.
    #
    def remove_all
      @connection.delete_by_query("type:#{@setup.clazz.name}")
    end

    protected

    # 
    # Need to prep to documents for passing to the connection add
    #
    def prepare(model)
      hash = static_hash_for(model)
      for field in @setup.all_fields
        hash.merge!(field.pairs_for(model))
      end
      hash
    end

    # 
    # All indexed documents index and store the +id+ and +type+ fields.
    # This method constructs the document hash containing those key-value
    # pairs.
    #
    def static_hash_for(model)
      { :id => Adapters::InstanceAdapter.adapt(model).index_id,
        :type => Util.superclasses_for(model.class).map { |clazz| clazz.name }}
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
