module Sunspot
  module SessionProxy
    # 
    # An abstract subclass of ShardingSessionProxy that shards by class.
    # Concrete subclasses should not override the #session_for method, but
    # should instead implement the #session_for_class method. They must also
    # still implement the #all_sessions method.
    #
    # Unlike its parent class, ClassShardingSessionProxy implements
    # #remove_by_id and all flavors of #remove_all.
    #
    class ClassShardingSessionProxy < ShardingSessionProxy
      # 
      # Remove the Session object pointing at the shard that indexes the given
      # class.
      #
      # <strong>Concrete subclasses must implement this method.</strong>
      #
      def session_for_class(clazz)
        raise NotImplementedError
      end

      # 
      # See Sunspot.remove_by_id
      #
      def remove_by_id(clazz, id)
        session_for_class(clazz).remove_by_id(clazz, id)
      end

      # 
      # See Sunspot.remove_by_id!
      #
      def remove_by_id!(clazz, id)
        session_for_class(clazz).remove_by_id!(clazz, id)
      end

      # 
      # See Sunspot.remove_all
      #
      def remove_all(clazz = nil)
        if clazz
          session_for_class(clazz).remove_all(clazz)
        else
          all_sessions.each { |session| session.remove_all }
        end
      end

      # 
      # See Sunspot.remove_all!
      #
      def remove_all!(clazz = nil)
        if clazz
          session_for_class(clazz).remove_all!(clazz)
        else
          all_sessions.each { |session| session.remove_all! }
        end
      end

      private

      def session_for(object)
        session_for_class(object.class)
      end
    end
  end
end
