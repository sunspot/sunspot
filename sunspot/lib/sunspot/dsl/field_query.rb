module Sunspot
  module DSL
    # 
    # Provides an API for areas of the query DSL that operate on specific
    # fields. This functionality is provided by the query DSL and the dynamic
    # query DSL.
    #
    class FieldQuery < Scope
      def initialize(search, query, setup) #:nodoc:
        @search, @query = search, query
        super(query.scope, setup)
      end

      # Specify the order that results should be returned in. This method can
      # be called multiple times; precedence will be in the order given.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: the field to use for ordering
      # direction<Symbol>:: :asc or :desc (default :asc)
      #
      def order_by(field_name, direction = nil)
        sort =
          if special = Sunspot::Query::Sort.special(field_name)
            special.new(direction)
          else
            Sunspot::Query::Sort::FieldSort.new(
              @setup.field(field_name), direction
            )
          end
        @query.add_sort(sort)
      end

      #
      # Specify that the results should be ordered based on their
      # distance from a given point.
      #
      # ==== Parameters
      #
      # field_name<Symbol>::
      #   the field that stores the location (declared as `latlon`)
      # lat<Numeric>::
      #   the reference latitude
      # lon<Numeric>::
      #   the reference longitude
      # direction<Symbol>::
      #   :asc or :desc (default :asc)
      # 
      def order_by_geodist(field_name, lat, lon, direction = nil)
        @query.add_sort(
          Sunspot::Query::Sort::GeodistSort.new(@setup.field(field_name), lat, lon, direction)
        )
      end

      # 
      # DEPRECATED Use <code>order_by(:random)</code>
      #
      def order_by_random
        order_by(:random)
      end

      # Specify a field for result grouping. Grouping groups documents
      # with a common field value, return only the top document per
      # group.
      #
      # More information in the Solr documentation:
      # <http://wiki.apache.org/solr/FieldCollapsing>
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: the field to use for grouping
      def group(*field_names, &block)
        field_names.each do |field_name|
          field = @setup.field(field_name)
          group = @query.add_group(Sunspot::Query::FieldGroup.new(field))
          @search.add_field_group(field)

          if block
            Sunspot::Util.instance_eval_or_call(
              FieldGroup.new(@setup, group),
              &block
            )
          end
        end
      end

      #
      # Request a facet on the search query. A facet is a feature of Solr that
      # determines the number of documents that match the existing search *and*
      # an additional criterion. This allows you to build powerful drill-down
      # interfaces for search, at each step presenting the searcher with a set
      # of refinements that are known to return results.
      #
      # In Sunspot, each facet returns zero or more rows, each of which
      # represents a particular criterion conjoined with the actual query being
      # performed. For _field_ _facets_, each row represents a particular value
      # for a given field. For _query_ _facets_, each row represents an
      # arbitrary scope; the facet itself is just a means of logically grouping
      # the scopes.
      #
      # === Examples
      #
      # ==== Field Facets
      #
      # A field facet is specified by passing one or more Symbol arguments to
      # this method:
      #
      #   Sunspot.search(Post) do
      #     with(:blog_id, 1)
      #     facet(:category_id)
      #   end
      #   
      # The facet specified above will have a row for each category_id that is
      # present in a document which also has a blog_id of 1.
      #
      # ==== Multiselect Facets
      #
      # In certain circumstances, it is beneficial to exclude certain query
      # scopes from a facet; the most common example is multi-select faceting,
      # where the user has selected a certain value, but the facet should still
      # show all options that would be available if they had not:
      #
      #   Sunspot.search(Post) do
      #     with(:blog_id, 1)
      #     category_filter = with(:category_id, 2)
      #     facet(:category_id, :exclude => category_filter)
      #   end
      # 
      # Although the results of the above search will be restricted to those
      # with a category_id of 2, the category_id facet will operate as if a
      # category had not been selected, allowing the user to select additional
      # categories (which will presumably be ORed together).
      # 
      # It possible to exclude multiple filters by passing an array:
      #
      #   Sunspot.search(Post) do
      #     with(:blog_id, 1)
      #     category_filter = with(:category_id, 2)
      #     author_filter = with(:author_id, 3)
      #     facet(:category_id,
      #           :exclude => [category_filter, author_filter].compact)
      #   end
      #
      # You should consider using +.compact+ to ensure that the array does not 
      # contain any nil values.
      #
      # <strong>As far as I can tell, Solr only supports multi-select with
      # field facets; if +:exclude+ is passed to a query facet, this method will
      # raise an error. Also, the +:only+ and +:extra+ options use query
      # faceting under the hood, so these can't be used with +:extra+ either.
      # </strong>
      #
      # ==== Query Facets
      #
      # A query facet is a collection of arbitrary scopes, each of which
      # represents a row. This is specified by passing a block into the #facet
      # method; the block then contains one or more +row+ blocks, each of which
      # creates a query facet row. The +row+ blocks follow the usual Sunspot
      # scope DSL.
      #
      # For example, a query facet can be used to facet over a set of ranges:
      #
      #   Sunspot.search(Post) do
      #     facet(:average_rating) do
      #       row(1.0..2.0) do
      #         with(:average_rating, 1.0..2.0)
      #       end
      #       row(2.0..3.0) do
      #         with(:average_rating, 2.0..3.0)
      #       end
      #       row(3.0..4.0) do
      #         with(:average_rating, 3.0..4.0)
      #       end
      #       row(4.0..5.0) do
      #         with(:average_rating, 4.0..5.0)
      #       end
      #     end
      #   end
      #
      # Note that the arguments to the +facet+ and +row+ methods simply provide
      # labels for the facet and its rows, so that they can be retrieved and
      # identified from the Search object. They are not passed to Solr and no
      # semantic meaning is attached to them. The label for +facet+ should be
      # a symbol; the label for +row+ can be whatever you'd like.
      #
      # ==== Range Facets
      #
      # One can use the Range Faceting feature on any date field or any numeric
      # field that supports range queries. This is particularly useful for the
      # cases in the past where one might stitch together a series of range
      # queries (as facet by query) for things like prices, etc.
      #
      # For example faceting over average ratings can be done as follows:
      #
      #   Sunspot.search(Post) do
      #     facet :average_rating, :range => 1..5, :range_interval => 1
      #   end
      #
      # ==== Parameters
      #
      # field_names...<Symbol>:: fields for which to return field facets
      #
      # ==== Options
      #
      # :sort<Symbol>::
      #   Either :count (values matching the most terms first) or :index (lexical)
      # :limit<Integer>::
      #   The maximum number of facet rows to return
      # :offset<Integer>::
      #   The offset from which to start returning facet rows
      # :minimum_count<Integer>::
      #   The minimum count a facet row must have to be returned
      # :zeros<Boolean>::
      #   Return facet rows for which there are no matches (equivalent to
      #   :minimum_count => 0). Default is false.
      # :exclude<Object,Array>::
      #   Exclude one or more filters when performing the faceting (see
      #   Multiselect Faceting above). The object given for this argument should
      #   be the return value(s) of a scoping method (+with+, +any_of+,
      #   +all_of+, etc.). <strong>Only can be used for field facets that do not
      #   use the +:extra+ or +:only+ options.</strong>
      # :name<Symbol>::
      #   Give a custom name to a field facet. The main use case for this option
      #   is for requesting the same field facet multiple times, using different
      #   filter exclusions (see Multiselect Faceting above). If you pass this
      #   option, it is also the argument that should be passed to Search#facet
      #   when retrieving the facet result.
      # :only<Array>::
      #   Only return facet rows for the given values. Useful if you are only
      #   interested in faceting on a subset of values for a given field.
      #   <strong>Only applies to field facets.</strong>
      # :extra<Symbol,Array>::
      #   One or more of :any and :none. :any returns a facet row with a count
      #   of all matching documents that have some value for this field. :none
      #   returns a facet row with a count of all matching documents that have
      #   no value for this field. The facet row(s) corresponding to the extras
      #   have a value of the symbol passed. <strong>Only applies to field
      #   facets.</strong>
      #
      def facet(*field_names, &block)
        options = Sunspot::Util.extract_options_from(field_names)

        if block
          if field_names.length != 1
            raise(
              ArgumentError,
              "wrong number of arguments (#{field_names.length} for 1)"
            )
          end
          search_facet = @search.add_query_facet(field_names.first, options)
          Sunspot::Util.instance_eval_or_call(
            QueryFacet.new(@query, @setup, search_facet, options),
            &block
          )
        elsif options[:only]
          if options.has_key?(:exclude)
            raise(
              ArgumentError,
              "can't use :exclude with :only (see documentation)"
            )
          end
          field_names.each do |field_name|
            field = @setup.field(field_name)
            search_facet = @search.add_field_facet(field, options)
            Util.Array(options[:only]).each do |value|
              facet = Sunspot::Query::QueryFacet.new
              facet.add_positive_restriction(field, Sunspot::Query::Restriction::EqualTo, value)
              @query.add_query_facet(facet)
              search_facet.add_row(value, facet.to_boolean_phrase)
            end
          end
        else
          field_names.each do |field_name|
            search_facet = nil
            field = @setup.field(field_name)
            facet =
              if options[:time_range]
                unless field.type.is_a?(Sunspot::Type::TimeType)
                  raise(
                    ArgumentError,
                    ':time_range can only be specified for Date or Time fields'
                  )
                end
                search_facet = @search.add_date_facet(field, options)
                Sunspot::Query::DateFieldFacet.new(field, options)
              elsif options[:range]
                unless [Sunspot::Type::TimeType, Sunspot::Type::FloatType, Sunspot::Type::IntegerType ].inject(false){|res,type| res || field.type.is_a?(type)}
                  raise(
                    ArgumentError,
                    ':range can only be specified for date or numeric fields'
                  )
                end
                search_facet = @search.add_range_facet(field, options)
                Sunspot::Query::RangeFacet.new(field, options)
              else
                search_facet = @search.add_field_facet(field, options)
                Sunspot::Query::FieldFacet.new(field, options)
              end
            @query.add_field_facet(facet)
            Util.Array(options[:extra]).each do |extra|
              if options.has_key?(:exclude)
                raise(
                  ArgumentError,
                  "can't use :exclude with :extra (see documentation)"
                )
              end
              extra_facet = Sunspot::Query::QueryFacet.new
              case extra
              when :any
                extra_facet.add_negated_restriction(
                  field,
                  Sunspot::Query::Restriction::EqualTo,
                  nil
                )
              when :none
                extra_facet.add_positive_restriction(
                  field,
                  Sunspot::Query::Restriction::EqualTo,
                  nil
                )
              else
                raise(
                  ArgumentError,
                  "Allowed values for :extra are :any and :none"
                )
              end
              search_facet.add_row(extra, extra_facet.to_boolean_phrase)
              @query.add_query_facet(extra_facet)
            end
          end
        end
      end

      def dynamic(base_name, &block)
        dynamic_field_factory = @setup.dynamic_field_factory(base_name)
        Sunspot::Util.instance_eval_or_call(
          FieldQuery.new(@search, @query, dynamic_field_factory),
          &block
        )
      end
    end
  end
end
