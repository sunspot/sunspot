module Sunspot
  module DSL #:nodoc:
    module Adjustable #:nodoc
      # <strong>Expert:</strong> Adjust or reset the parameters passed to Solr.
      # The adjustment will take place just before sending the params to solr,
      # after Sunspot builds the Solr params based on the methods called in the
      # DSL.
      #
      # Under normal circumstances, using this method should not be necessary;
      # if you find that it is, please consider submitting a feature request.
      # Using this method requires knowledge of Sunspot's internal Solr schema
      # and Solr query representations, which are not part of Sunspot's public
      # API; they could change at any time. <strong>This method is unsupported
      # and your mileage may vary.</strong>
      #
      # ==== Examples
      #
      #   Sunspot.search(Post) do
      #     adjust_solr_params do |params|
      #       params[:q] += ' AND something_s:more'
      #     end
      #   end
      #
      #   Sunspot.more_like_this(my_post) do
      #     adjust_solr_params do |params|
      #       params["mlt.match.include"] = true
      #     end
      #   end
      # 
      def adjust_solr_params( &block )
        @query.solr_parameter_adjustment = block
      end
    end
  end
end
