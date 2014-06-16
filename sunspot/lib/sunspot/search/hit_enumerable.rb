module Sunspot
  module Search
    module HitEnumerable #:nodoc:
      def hits(options = {})
        if options[:verify]
          verified_hits
        elsif solr_docs
          solr_docs.map { |d| Hit.new(d, highlights_for(d), self) }
        else
          []
        end
      end

      def verified_hits
        hits.select { |h| h.result }
      end

      # 
      # Populate the Hit objects with their instances. This is invoked the first
      # time any hit has its instance requested, and all hits are loaded as a
      # batch.
      #
      def populate_hits #:nodoc:
        id_hit_hash = Hash.new { |h, k| h[k] = {} }
        hits.each do |hit|
          id_hit_hash[hit.class_name][hit.primary_key] = hit
        end
        id_hit_hash.each_pair do |class_name, hits|
          ids = hits.map { |id, hit| hit.primary_key }
          data_accessor = data_accessor_for(Util.full_const_get(class_name))          
          hits_for_class = id_hit_hash[class_name]
          data_accessor.load_all(ids).each do |result|
            hit = hits_for_class.delete(Adapters::InstanceAdapter.adapt(result).id.to_s)
            hit.result = result
          end
          hits_for_class.values.each { |hit| hit.result = nil }
        end
      end

      #
      # Convenience method to iterate over hit and result objects. Block is
      # yielded a Sunspot::Server::Hit instance and a Sunspot::Server::Result
      # instance.
      #
      # Note that this method iterates over verified hits (see #hits method
      # for more information).
      #
      def each_hit_with_result
        return enum_for(:each_hit_with_result) unless block_given?
        verified_hits.each { |hit| yield hit, hit.result }
      end

      # 
      # Get the data accessor that will be used to load a particular class out of
      # persistent storage. Data accessors can implement any methods that may be
      # useful for refining how data is loaded out of storage. When building a
      # search manually (e.g., using the Sunspot#new_search method), this should
      # be used before calling #execute(). Use the
      # Sunspot::DSL::Search#data_accessor_for method when building searches using
      # the block DSL.
      #
      def data_accessor_for(clazz) #:nodoc:
        @registry ||= Sunspot::Adapters::Registry.new
        @registry.retrieve(clazz)
      end
    end
  end
end
