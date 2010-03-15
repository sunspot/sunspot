module Sunspot
  module Query
    class Query
      attr_accessor :scope, :fulltext, :parameter_adjustment

      def initialize(types)
        @scope = Scope.new
        @sort = SortComposite.new
        @components = []
        if types.length == 1
          @scope.add_restriction(TypeField.instance, Restriction::EqualTo, types.first)
        else
          @scope.add_restriction(TypeField.instance, Restriction::AnyOf, types)
        end
      end

      def set_fulltext(keywords)
        @fulltext = Dismax.new(keywords)
      end
      
      def set_solr_parameter_adjustment( block )
        @parameter_adjustment = block
      end

      def add_location_restriction(coordinates, radius)
        @local = Local.new(coordinates, radius)
      end

      def add_sort(sort)
        @sort << sort
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
        Sunspot::Util.deep_merge!(params, @sort.to_params)
        Sunspot::Util.deep_merge!(params, @pagination.to_params) if @pagination
        Sunspot::Util.deep_merge!(params, @local.to_params) if @local
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
    end
  end
end
