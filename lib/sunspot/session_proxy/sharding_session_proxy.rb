require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    class ShardingSessionProxy < AbstractSessionProxy
      not_supported :batch, :config, :remove_by_id, :remove_by_id!

      def initialize(search_session = Sunspot.session.new)
        @search_session = search_session
      end

      def index(*objects)
        using_sharded_session(objects) { |session, group| session.index(group) }
      end

      def index!(*objects)
        using_sharded_session(objects) { |session, group| session.index!(group) }
      end

      def remove(*objects)
        using_sharded_session(objects) { |session, group| session.remove(group) }
      end

      def remove!(*objects)
        using_sharded_session(objects) { |session, group| session.remove!(group) }
      end

      def remove_all(clazz = nil)
        if clazz
          raise NotSupportedError, "Sharding session proxy does not support remove_all with an argument."
        else
          all_sessions.each { |session| session.remove_all }
        end
      end

      def remove_all!(clazz = nil)
        if clazz
          raise NotSupportedError, "Sharding session proxy does not support remove_all! with an argument."
        else
          all_sessions.each { |session| session.remove_all! }
        end
      end

      def commit
        all_sessions.each { |session| session.commit }
      end

      def commit_if_dirty
        all_sessions.each { |session| session.commit_if_dirty }
      end

      def commit_if_delete_dirty
        all_sessions.each { |session| session.commit_if_delete_dirty }
      end

      def new_search(*types)
        shard_urls = all_sessions.map { |session| session.config.solr.url }
        search = @search_session.new_search(*types)
        search.build do
          adjust_solr_params { |params| params[:shards] = shard_urls.join(',') }
          # I feel a little dirty doing this.
        end
        search
      end

      def search(*types, &block)
        new_search(*types).execute
      end

      def dirty?
        all_sessions.any? { |session| session.dirty? }
      end

      def delete_dirty?
        all_sessions.any? { |session| session.delete_dirty? }
      end

      private

      def using_sharded_session(objects)
        grouped_objects = Hash.new { |h, k| h[k] = [] }
        objects.flatten.each { |object| grouped_objects[session_for(object)] << object }
        grouped_objects.each_pair do |session, group|
          yield(session, group)
        end
      end
    end
  end
end
