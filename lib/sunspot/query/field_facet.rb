require 'set'

module Sunspot
  module Query
    #
    # Encapsulates a query component representing a field facet. Users create
    # instances using DSL::Query#facet
    #
    class FieldFacet #:nodoc:
      class <<self
        protected :new

        # 
        # Return the appropriate FieldFacet instance for the field and options.
        # If a :time_range option is specified, and the field type is TimeType,
        # build a DateFieldFacet. Otherwise, build a normal FieldFacet.
        #
        # ==== Returns
        #
        # FieldFacet:: FieldFacet instance of appropriate class.
        #
        def build(field, options)
          if options.has_key?(:time_range)
            unless field.type == Type::TimeType
              raise(
                ArgumentError,
                ":time_range key can only be specified for time fields"
              )
            end
            DateFieldFacet.new(field, options)
          elsif options.has_key?(:only)
            QueryFieldFacet.new(field, options.delete(:only))
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
        params = { :"facet.field" => [@field.indexed_name], :facet => 'true' }
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

      # 
      # Given a facet parameter name, return the appropriate Solr parameter for
      # this facet.
      #
      # ==== Returns
      #
      # Symbol:: Solr query parameter key
      #
      def param_key(name)
        :"f.#{@field.indexed_name}.facet.#{name}"
      end
    end

    class DateFieldFacet < FieldFacet #:nodoc:
      ALLOWED_OTHER = Set.new(%w(before after between none all))

      # 
      # Convert the facet to date params.
      #
      def to_params
        super.merge(
          :"facet.date" => [@field.indexed_name],
          param_key('date.start') => start_time.utc.xmlschema,
          param_key('date.end') => end_time.utc.xmlschema,
          param_key('date.gap') => "+#{interval}SECONDS"
        )
      end

      private

      # 
      # Start time for facet range
      #
      # ==== Returns
      #
      # Time:: Start time
      #
      def start_time
        @options[:time_range].first
      end

      # 
      # End time for facet range
      #
      # ==== Returns
      #
      # Time:: End time
      #
      def end_time
        @options[:time_range].last
      end

      # 
      # Time interval that each facet row should cover. Default is 1 day.
      #
      # ===== Returns
      #
      # Integer:: Time interval in seconds
      #
      def interval
        @options[:time_interval] || 86400
      end

      # 
      # Other time ranges to create facet rows for. Allowed values are defined
      # in ALLOWED_OTHER constant.
      #
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
