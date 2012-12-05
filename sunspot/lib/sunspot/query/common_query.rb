module Sunspot
  module Query #:nodoc:
    class CommonQuery
      def initialize(types)
        @scope = Scope.new
        @sort = SortComposite.new
        @components = [@scope, @sort]
        if types.length == 1
          @scope.add_positive_restriction(TypeField.instance, Restriction::EqualTo, types.first)
        else
          @scope.add_positive_restriction(TypeField.instance, Restriction::AnyOf, types)
        end

        @pagination = nil
        @parameter_adjustment = nil
      end

      def solr_parameter_adjustment=(block)
        @parameter_adjustment = block
      end

      def add_sort(sort)
        @sort << sort
      end

      def add_group(group)
        @components << group
        group
      end

      def add_field_facet(facet)
        @components << facet
        facet
      end

      def add_query_facet(facet)
        @components << facet
        facet
      end

      def add_function(function)
        @components << function
        function
      end

      def add_geo(geo)
        @components << geo
        geo
      end

      def paginate(page, per_page, offset = nil)
        if @pagination
          @pagination.offset = offset
          @pagination.page = page
          @pagination.per_page = per_page
        else
          @components << @pagination = Pagination.new(page, per_page, offset)
        end
      end

      def to_params
        params = {}
        @components.each do |component|
          Sunspot::Util.deep_merge!(params, component.to_params)
        end
        @parameter_adjustment.call(params) if @parameter_adjustment
        params[:q] ||= '*:*'
        params
      end

      def [](key)
        to_params[key.to_sym]
      end

      def page
        @pagination.page if @pagination
      end

      def per_page
        @pagination.per_page if @pagination
      end


      private

      #
      # If we have a single fulltext query, merge is normally. If there are
      # multiple nested queries, serialize them as `_query_` subqueries.
      #
      def merge_fulltext(params)
        return nil if @fulltexts.empty?
        return Sunspot::Util.deep_merge!(params, @fulltexts.first.to_params) if @fulltexts.length == 1
        subqueries = @fulltexts.map {|fulltext| fulltext.to_subquery }.join(' ')
        Sunspot::Util.deep_merge!(params, {:q => subqueries})
      end

    end
  end
end
