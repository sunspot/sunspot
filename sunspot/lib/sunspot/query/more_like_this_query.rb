module Sunspot
  module Query
    class MoreLikeThisQuery
      attr_accessor :scope, :parameter_adjustment

      class Scope < Connective::Conjunction
	def to_params
	  { :q => @components.map { |component| component.to_filter_query }}
	end
      end

      def initialize()
	@scope = Scope.new
	@fields = {}
	@options = {}
      end

      def reset_fields
	@fields = {}
      end
      
      def add_field(field, boost = nil)
	raise(ArgumentError, "field is not setup for more_like_this") unless field.more_like_this?
        @fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      def set_solr_parameter_adjustment( block )
        @parameter_adjustment = block
      end

      def set_minimum_term_frequency(value)
	@options["mlt.mintf"] = value
      end

      def set_minimum_document_frequency(value)
	@options["mlt.mindf"] = value
      end

      def set_minimum_word_length(value)
	@options["mlt.minwl"] = value
      end

      def set_maximum_word_length(value)
	@options["mlt.maxwl"] = value
      end
      
      def set_maximum_query_terms(value)
	@options["mlt.maxqt"] = value
      end

      def set_boost_by_relevance(should_boost)
	@options["mlt.boost"] = should_boost
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
        params = {}
	Sunspot::Util.deep_merge!(params, @scope.to_params) # add :q => "id:Post\\ 1"
	Sunspot::Util.deep_merge!(params, @options) # add mlt.xxx options
        Sunspot::Util.deep_merge!(params, @pagination.to_params) if @pagination

	params["mlt.fl"] = @fields.keys.join(",")

	boosted_fields = @fields.values.select { |field| field.boost }
        params[:qf] = boosted_fields.map { |field| field.to_boosted_field }.join(' ') unless boosted_fields.empty?

        @parameter_adjustment.call(params) if @parameter_adjustment

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
