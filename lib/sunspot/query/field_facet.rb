require 'set'

module Sunspot
  class Query
    #
    # Encapsulates a query component representing a field facet. Users create
    # instances using DSL::Query#facet
    #
    class FieldFacet #:nodoc:
      class <<self
        protected :new

        def build(field, options)
          if options.has_key?(:time_range)
            DateFieldFacet.new(field, options)
          else
            FieldFacet.new(field, options)
          end
        end
      end

      def initialize(field, options)
        @field, @options = field, options
      end

      # ==== Returns
      #
      # Hash:: solr-ruby params for this field facet
      #
      def to_params
        params = { :"facet.field" => [@field.indexed_name], 'facet' => 'true' }
        params[param_key(:sort)] = 
          case @options[:sort]
          when :count then 'true'
          when :index then 'false'
          when nil
          else raise(ArgumentError, 'Allowed facet sort options are :count and :index')
          end
        params[param_key(:limit)] = @options[:limit]
        params[param_key(:mincount)] =
          if @options[:minimum_count] then @options[:minimum_count]
          elsif @options[:zeros] then 0
          else 1
          end
        params
      end

      private

      def param_key(name)
        :"f.#{@field.indexed_name}.facet.#{name}"
      end
    end

    class DateFieldFacet < FieldFacet
      ALLOWED_OTHER = Set.new(%w(before after between none all))

      def to_params
        super.merge(
          :"facet.date" => [@field.indexed_name],
          param_key('date.start') => start_time.utc.xmlschema,
          param_key('date.end') => end_time.utc.xmlschema,
          param_key('date.gap') => "+#{interval}SECONDS",
          param_key('date.other') => others
        )
      end

      private

      def start_time
        @options[:time_range].first
      end

      def end_time
        @options[:time_range].last
      end

      def interval
        @options[:time_interval] || 86400
      end

      def others
        if others = @options[:time_other]
          Array(others).map do |other|
            other = other.to_s
            unless ALLOWED_OTHER.include?(other)
              raise(
                ArgumentError,
                "#{other.inspect} is not a valid argument for :time_other"
              )
            end
            other
          end
        end
      end
    end
  end
end
