module Sunspot
  module DSL #:nodoc:
    #
    # This class provides the DSL for MoreLikeThis queries.
    #
    class MoreLikeThis
      include Paginatable, Adjustable

      def initialize(query, setup)
	@query, @setup = query, setup
      end

      def fields(*field_names)
	@query.reset_fields # remove default fields

        boosted_fields = field_names.pop if field_names.last.is_a?(Hash)
	field_names.each do |name|
	  mlt_fields = @setup.more_like_this_fields(name)
	  raise(ArgumentError, "Field #{name} is not setup for more_like_this") if mlt_fields.empty?
	  mlt_fields.each { |field| @query.add_field(field) }
	end
	if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @setup.more_like_this_fields(field_name).each { |field| @query.add_field(field, boost) }
          end
	end
      end

      def minimum_term_frequency(value)
	@query.set_minimum_term_frequency(value)
      end
      alias_method :mintf, :minimum_term_frequency
      
      def minimum_document_frequency(value)
	@query.set_minimum_document_frequency(value)
      end
      alias_method :mindf, :minimum_document_frequency

      def minimum_word_length(value)
	@query.set_minimum_word_length(value)
      end
      alias_method :minwl, :minimum_word_length

      def maximum_word_length(value)
	@query.set_maximum_word_length(value)
      end
      alias_method :maxwl, :maximum_word_length
      
      def maximum_query_terms(value)
	@query.set_maximum_query_terms(value)
      end
      alias_method :maxqt, :maximum_query_terms

      def boost_by_relevance(should_boost)
	@query.set_boost_by_relevance(should_boost)
      end
      alias_method :boost, :boost_by_relevance
    end
  end
end
