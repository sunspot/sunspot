module Sunspot
  module Search
    class FieldGroup
      def initialize(field, search, options) #:nodoc:
        @field, @search, @options = field, search, options
      end

      def groups
        @groups ||=
          begin
            if solr_response
              solr_response['groups'].map do |group|
                Group.new(group['groupValue'], group['doclist'], @search)
              end
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
