module Sunspot
  module DSL #:nodoc:
    #
    # This class provides the DSL for MoreLikeThis queries.
    #
    class MoreLikeThisQuery < FieldQuery
      include Paginatable, Adjustable

      def fields(*field_names)
        boosted_fields = field_names.pop if field_names.last.is_a?(Hash)
        field_names.each do |name|
          mlt_fields = @setup.more_like_this_fields(name)
          raise(ArgumentError, "Field #{name} is not setup for more_like_this") if mlt_fields.empty?
          mlt_fields.each { |field| @query.more_like_this.add_field(field) }
        end
        if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @setup.more_like_this_fields(field_name).each do |field|
              @query.more_like_this.add_field(field, boost)
            end
          end
        end
      end

      def minimum_term_frequency(value)
        @query.more_like_this.minimum_term_frequency = value
      end
      alias_method :mintf, :minimum_term_frequency
      
      def minimum_document_frequency(value)
        @query.more_like_this.minimum_document_frequency = value
      end
      alias_method :mindf, :minimum_document_frequency

      def minimum_word_length(value)
        @query.more_like_this.minimum_word_length = value
      end
      alias_method :minwl, :minimum_word_length

      def maximum_word_length(value)
        @query.more_like_this.maximum_word_length = value
      end
      alias_method :maxwl, :maximum_word_length
      
      def maximum_query_terms(value)
        @query.more_like_this.maximum_query_terms = value
      end
      alias_method :maxqt, :maximum_query_terms

      def boost_by_relevance(should_boost)
        @query.more_like_this.boost_by_relevance = should_boost
      end
      alias_method :boost, :boost_by_relevance
    end
  end
end
