module Sunspot
  module Search
    class FieldGroup
      def initialize(field, search) #:nodoc:
        @field, @search = field, search
      end

      def groups
        @groups ||=
          if solr_response
            solr_response['groups'].map do |group|
              Group.new(group['groupValue'], group['doclist'], @search)
            end
          end
      end

      def matches
        if solr_response
          solr_response['matches'].to_i
        end
      end

      private

      def solr_response
        @search.group_response[@field.indexed_name.to_s]
      end
    end
  end
end
