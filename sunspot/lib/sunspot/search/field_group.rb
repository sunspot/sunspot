require 'sunspot/search/paginated_collection'

module Sunspot
  module Search
    class FieldGroup
      def initialize(field, search) #:nodoc:
        @field, @search = field, search
      end

      def groups
        @groups ||=
          if solr_response
            paginate_collection(
              solr_response['groups'].map do |group|
                Group.new(group['groupValue'], group['doclist'], @search)
              end
            )
          end
      end

      def matches
        if solr_response
          solr_response['matches'].to_i
        end
      end

      def total
        if solr_response
          solr_response['ngroups'].to_i
        end
      end

      #
      # It populates all grouped hits at once.
      # Useful for eager loading fall grouped results at once.
      #
      def populate_all_hits
        # Init a 2 dimension Hash that contains an array per key
        id_hit_hash = Hash.new { |hash, key| hash[key] = Hash.new{ |h, k| h[k] = [] } }
        groups.each do |g|
          # Take all hits to being populated later on
          g.hits.each do |hit|
            id_hit_hash[hit.class_name][hit.primary_key] |= [hit]
          end
        end
        # Go for each class and load the results' objects into each of the hits
        id_hit_hash.each_pair do |class_name, many_hits|
          ids = many_hits.keys
          data_accessor = @search.data_accessor_for(Util.full_const_get(class_name))
          hits_for_class = id_hit_hash[class_name]
          data_accessor.load_all(ids).each do |result|
            hits = hits_for_class.delete(Adapters::InstanceAdapter.adapt(result).id.to_s)
            hits.each{ |hit| hit.result = result }
          end
          hits_for_class.values.each { |hits| hits.each{|hit| hit.result = nil } }
        end
      end

      private

      def solr_response
        @search.group_response[@field.indexed_name.to_s]
      end

      def paginate_collection(collection)
        PaginatedCollection.new(collection, @search.query.page, @search.query.per_page, total)
      end
    end
  end
end
