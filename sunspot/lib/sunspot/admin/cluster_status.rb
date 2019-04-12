module Sunspot
  module ADMIN
    #
    # Cluster Maintenance
    #
    module Cluster
      attr_reader :replicas_not_active

      #
      # Return the cluster status
      #
      # @param [Boolean] as_json: specify the type of the status to return
      #
      #
      def clusterstatus(as_json: false)
        # don't cache it
        status = solr_request('CLUSTERSTATUS')
        if as_json
          status.to_json
        else
          status
        end
      end

      ##
      # Generate a report of the current collection/shards status
      # as: type of rapresentation
      #  - :table
      #  - :json
      #  - :simple
      # using_persisted: if true doesn't make a request to SOLR
      #                  but use the persisted state
      def report_clusterstatus(as: :table, using_persisted: false)
        rows = using_persisted ? restore_solr_status : check_cluster

        case as
        when :table
          # order first by STATUS then by COLLECTION (name)
          rows = sort_rows(rows)

          table = Terminal::Table.new(
            headings: [
              'Collection',
              'Replica Factor',
              'Shards',
              'Shard Active',
              'Shard Down',
              'Shard Good',
              'Shard Bad',
              'Replica UP',
              'Replica DOWN',
              'Status',
              'Recoverable'
            ],
            rows: rows.map do |row|
              [
                row[:collection],
                row[:num_replicas],
                row[:num_shards],
                row[:shard_active],
                row[:shard_non_active],
                row[:shard_good],
                row[:shard_bad],
                row[:replicas_up],
                row[:replicas_down],
                row[:gstatus] ? 'OK' : 'BAD',
                row[:recoverable] ? 'YES' : 'NO'
              ]
            end
          )
          puts table
        when :json
          status = rows.each_with_object({}) do |row, acc|
            name = row[:collection]
            row.delete(:collection)
            acc[name] = row
          end
          status.to_json
        when :simple
          status = 'green'
          bad_collections = []

          rows.each do |row|
            if row[:status] == :bad && row[:recoverable] == :no
              status = 'red'
              bad_collections << {
                collection: row[:collection],
                base_url: row[:bad_urls],
                recoverable: false
              }
            elsif row[:status] == :bad && row[:recoverable] == :yes
              status = 'orange' unless status == 'red'
              bad_collections << {
                collection: row[:collection],
                base_url: row[:bad_urls],
                recoverable: true
              }
            elsif row[:bad_urls].count > 0
              bad_collections << {
                collection: row[:collection],
                base_url: row[:bad_urls],
                recoverable: true
              }
            end
          end
          { status: status, bad_collections: bad_collections }
        end
      end

      #
      # Persist SOLR status to file (using pstore)
      #
      def persist_solr_status
        cluster = clusterstatus
        rows = check_cluster(status: cluster)

        # store to disk the current status
        store = PStore.new('cluster_stauts.pstore')
        store.transaction do
          # only for debug
          store['solr_cluster_status'] = cluster

          # save rows
          store['solr_cluster_status_rows'] = rows
          store['replicas_not_active'] = @replicas_not_active
        end
      end

      #
      # Return the SOLR status stored in a persisted store
      #
      def restore_solr_status
        store = PStore.new('cluster_stauts.pstore')
        store.transaction(true) do
          @replicas_not_active = store['replicas_not_active'] || []
          store['solr_cluster_status_rows']
        end
      end

      # rep is the collection to be repaired
      def repair_collection(rep)
        delete_failed_replica(collection: rep[:collection], shard: rep[:shard], replica: rep[:replica])
        add_failed_replica(collection: rep[:collection], shard: rep[:shard], node: rep[:node])
      end

      def repair_all_collections
        @replicas_not_active.each do |rep|
          repair_collection(rep) if rep[:recoverable]
        end
      end

      # Helper function for SOLR recovery
      def delete_failed_replica(collection:, shard:, replica:)
        solr_request(
          'DELETEREPLICA',
          extra_params: {
            'collection' => collection,
            'shard' => shard,
            'replica' => replica
          }
        )
      rescue RSolr::Error::Http => _e
        false
      end

      def add_failed_replica(collection:, shard:, node:)
        solr_request(
          'ADDREPLICA',
          extra_params: {
            'collection' => collection,
            'shard' => shard,
            'node' => node
          }
        )
      rescue RSolr::Error::Http => _e
        false
      end

      private

      def check_cluster(status: nil)
        @replicas_not_active.clear
        cluster = status || clusterstatus
        analyze_collections(cluster['cluster']['collections'])
      end

      def analyze_collections(collections)
        rows = []
        collections.each_pair do |collection_name, cs|
          replica_factor = cs['replicationFactor'].to_i
          shards = cs['shards']
          shard_status = get_shard_status(collection_name, shards)
          s_active = shard_status[:active]
          s_bad = shard_status[:bad]
          status = s_active.zero? || s_bad > 0 ? :bad : :ok
          recoverable = s_active > 0 && s_bad.zero?

          @replicas_not_active = @replicas_not_active.map do |r|
            nr = r.dup
            nr[:recoverable] = recoverable if r[:collection] == collection_name
            nr
          end

          rows << {
            collection: collection_name,
            num_replicas: replica_factor,
            num_shards: shards.count,
            shard_active: shard_status[:active],
            shard_non_active: shard_status[:non_active],
            shard_good: shard_status[:good],
            shard_bad: shard_status[:bad],
            replicas_up: shard_status[:replica_up],
            replicas_down: shard_status[:replica_down],
            status: status,
            recoverable: recoverable,
            bad_urls: @bad_urls[collection_name]
          }
        end

        rows
      end

      def get_shard_status(collection_name, shards)
        empty = {
          active: 0, non_active: 0,
          good: 0, bad: 0,
          replica_up: 0, replica_down: 0
        }

        shards.each_with_object(empty) do |(shard_name, v), acc|
          acc[:active] += 1 if v['state'] == 'active'
          acc[:non_active] += 1 if v['state'] != 'active'

          replica_status = get_replicas_status(
            collection_name,
            shard_name,
            v['replicas']
          )
          acc[:replica_up] += replica_status[:active]
          acc[:replica_down] += replica_status[:non_active]

          acc[:good] += 1 if replica_status[:active] > 0
          acc[:bad] += 1 if replica_status[:active] == 0
        end
      end

      def get_replicas_status(collection_name, shard_name, replicas)
        @bad_urls = Hash.new { |hash, key| hash[key] = [] }

        replicas.each_with_object(
          active: 0, non_active: 0
        ) do |(core_name, v), memo|
          if v['state'] == 'active'
            memo[:active] += 1
          else
            memo[:non_active] += 1
            @bad_urls[collection_name] << v['base_url']
            @replicas_not_active << {
              collection: collection_name,
              shard: shard_name,
              replica: core_name,
              node: v['node_name'],
              base_url: v['base_url']
            }
          end
        end
      end

      def sort_rows(rows)
        rows.map! do |row|
          row[:gstatus] = row[:status] == :ok && row[:replicas_up].positive?
          row
        end

        failed = rows
                .select { |row| row[:gstatus] == false }
                .sort_by { |a| a[:collection] }

        valid = rows
                .select { |row| row[:gstatus] == true }
                .sort_by { |a| a[:collection] }

        failed + valid
      end
    end
  end
end
