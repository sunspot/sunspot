module Sunspot
  module SessionProxy
    class ClassShardingSessionProxy < ShardingSessionProxy

      def remove_by_id(clazz, id)
        session_for_class(clazz).remove_by_id(clazz, id)
      end

      def remove_by_id!(clazz, id)
        session_for_class(clazz).remove_by_id!(clazz, id)
      end

      def remove_all(clazz = nil)
        if clazz
          session_for_class(clazz).remove_all(clazz)
        else
          all_sessions.each { |session| session.remove_all }
        end
      end

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
