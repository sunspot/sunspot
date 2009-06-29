require 'enumerator'

module Sunspot
  #
  # The facet class encapsulates the information returned by Solr for a
  # particular facet request.
  #
  # See http://wiki.apache.org/solr/SolrFacetingOverview for more information
  # on Solr's faceting capabilities.
  #
  class Facet
    attr_reader :field

    def initialize(facet_values, field) #:nodoc:
      @facet_values, @field = facet_values, field
    end

    # The name of the field that contains this facet's values
    #
    # ==== Returns
    #
    # Symbol:: The field name
    # 
    def field_name
      @field.name
    end

    # The rows returned for this facet.
    #
    # ==== Returns
    #
    # Array:: Collection of FacetRow objects, in the order returned by Solr
    # 
    def rows
      @rows ||=
        begin
          rows = []
          @facet_values.each_slice(2) do |pair|
            rows << new_row(pair)
          end
          rows
        end
    end

    private

    def new_row(pair)
      FacetRow.new(pair, self)
    end
  end
end
