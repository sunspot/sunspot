module Sunspot
  module Query
    class DateFieldJsonFacet < AbstractJsonFieldFacet

      def initialize(field, options, setup)
        raise Exception.new('Need to specify a time_range') if options[:time_range].nil?
        @start = options[:time_range].first
        @end = options[:time_range].last
        @gap = "+#{options[:gap] || 86400}SECONDS"
        super
      end

      def field_name_with_local_params
        params = {}
        params[:type] = 'range'
        params[:field] = @field.indexed_name
        params[:start] = @field.to_indexed(@start)
        params[:end] = @field.to_indexed(@end)
        params[:gap] = @gap

        # params[:mincount] =
        # params[:hardened] =
        # params[:other] =
        # params[:inclusive] =

        params.merge!(init_params)

        { @field.name => params }
      end
    end
  end
end


# field – The numeric field or date field to produce range buckets from
# mincount – Minimum document count for the bucket to be included in the response. Defaults to 0.
#   start – Lower bound of the ranges
#                                   end – Upper bound of the ranges
# gap – Size of each range bucket produced
# hardend – A boolean, which if true means that the last bucket will end at “end” even if it is less than “gap” wide. If false, the last bucket will be “gap” wide, which may extend past “end”.
#   other – This param indicates that in addition to the counts for each range constraint between facet.range.start and facet.range.end, counts should also be computed for…
# "before" all records with field values lower then lower bound of the first range
# "after" all records with field values greater then the upper bound of the last range
# "between" all records with field values between the start and end bounds of all ranges
# "none" compute none of this information
# "all" shortcut for before, between, and after
# include – By default, the ranges used to compute range faceting between facet.range.start and facet.range.end are inclusive of their lower bounds and exclusive of the upper bounds. The “before” range is exclusive and the “after” range is inclusive. This default, equivalent to lower below, will not result in double counting at the boundaries. This behavior can be modified by the facet.range.include param, which can be any combination of the following options…
# "lower" all gap based ranges include their lower bound
# "upper" all gap based ranges include their upper bound
# "edge" the first and last gap ranges include their edge bounds (ie: lower for the first one, upper for the last one) even if the corresponding upper/lower option is not specified
# "outer" the “before” and “after” ranges will be inclusive of their bounds, even if the first or last ranges already include those boundaries.
#   "all" s