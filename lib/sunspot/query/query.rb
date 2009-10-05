module Sunspot
  module Query
    class Query
      attr_accessor :scope
      attr_accessor :fulltext

      def initialize(types)
        @scope = Scope.new
        @field_facets = []
        @query_facets = {}
        @sort = SortComposite.new
        if types.length == 1
          @scope.add_restriction(TypeField.instance, Restriction::EqualTo, types.first)
        else
          @scope.add_restriction(TypeField.instance, Restriction::AnyOf, types)
        end
      end

      def set_fulltext(keywords)
        @fulltext = Dismax.new(keywords)
      end

      def add_location_restriction(coordinates, radius)
        @local = Local.new(coordinates, radius)
      end

      def add_field_facet(field, options = {})
        facet = FieldFacet.build(field, options)
        if facet.is_a?(QueryFacet)
          @query_facets[field.name.to_sym] = facet
        else
          @field_facets << facet
        end
      end

      def add_query_facet(name, options = {})
        @query_facets[name.to_sym] = QueryFacet.new(name, options)
      end

      def add_sort(sort)
        @sort << sort
      end

      def paginate(page, per_page)
        if @pagination
          @pagination.page = page
          @pagination.per_page = per_page
        else
          @pagination = Pagination.new(page, per_page)
        end
      end

      def to_params
        params = @scope.to_params
        Sunspot::Util.deep_merge!(params, @fulltext.to_params) if @fulltext
        @field_facets.each do |facet|
          Sunspot::Util.deep_merge!(params, facet.to_params)
        end
        @query_facets.values.each do |facet|
          Sunspot::Util.deep_merge!(params, facet.to_params)
        end
        Sunspot::Util.deep_merge!(params, @sort.to_params)
        Sunspot::Util.deep_merge!(params, @pagination.to_params) if @pagination
        Sunspot::Util.deep_merge!(params, @local.to_params) if @local
        params[:q] ||= '*:*'
        params
      end

      def page
        @pagination.page if @pagination
      end

      def per_page
        @pagination.per_page if @pagination
      end

      def query_facet(name)
        @query_facets[name] if @query_facets
      end
    end
  end
end
