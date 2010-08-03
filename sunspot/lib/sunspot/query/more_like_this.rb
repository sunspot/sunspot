module Sunspot
  module Query
    class MoreLikeThis
      attr_reader :fields

      def initialize(document)
        @document_scope = Restriction::EqualTo.new(
          false,
          IdField.instance,
          Adapters::InstanceAdapter.adapt(document).index_id
        )
        @fields = {}
        @params = {}
      end

      def add_field(field, boost = nil)
        raise(ArgumentError, "Field #{field.name} is not set up for more_like_this") unless field.more_like_this?
        @fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      def minimum_term_frequency=(mintf)
        @params[:"mlt.mintf"] = mintf
      end

      def minimum_document_frequency=(mindf)
        @params[:"mlt.mindf"] = mindf
      end

      def minimum_word_length=(minwl)
        @params[:"mlt.minwl"] = minwl
      end

      def maximum_word_length=(maxwl)
        @params[:"mlt.maxwl"] = maxwl
      end
      
      def maximum_query_terms=(maxqt)
        @params[:"mlt.maxqt"] = maxqt
      end

      def boost_by_relevance=(should_boost)
        @params[:"mlt.boost"] = should_boost
      end

      def to_params
        params = Sunspot::Util.deep_merge(
          @params,
          :q => @document_scope.to_boolean_phrase
        )
        params[:"mlt.fl"] = @fields.keys.join(",")
        boosted_fields = @fields.values.select { |field| field.boost }
        unless boosted_fields.empty?
          params[:qf] = boosted_fields.map do |field|
            field.to_boosted_field
          end.join(' ')
        end
        params
      end
    end
  end
end
