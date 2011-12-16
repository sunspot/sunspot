module Sunspot
  module DSL
    class RestrictionWithNear < Restriction
      def initialize(field, scope, query, negated)
        super(field, scope, negated)
        @query = query
      end

      # 
      # Perform a Geohash-based location restriction for the given `location`
      # field. Though this uses the same API as other attribute-field
      # restrictions, there are several differences between this and other
      # scoping methods:
      #
      # * It can only be called from the top-level query; it cannot be nested
      #   in a `dynamic`, `any_of`, or `all_of` block. This is because geohash
      #   queries are not sent to Solr as filter queries like other scopes, but
      #   rather are part of the fulltext query sent to Solr.
      # * Because it is included with the fulltext query (if any), location
      #   restrictions can be given boost. By default, an "exact"
      #   (maximum-precision) match will give the result a boost of 1.0; each
      #   lower level of precision gives a boost of 1/2 the next highest
      #   precision. See below for options to modify this behavior.
      #
      # ==== What is a Geohash?
      #
      # Geohash is a clever algorithm that creates a decodable digest of a
      # geographical point. It does this by dividing the globe into
      # quadrants, encoding the quadrant in which the point sits in the hash,
      # dividing the quadrant into smaller quadrants, and repeating an arbitrary
      # number of times (the "precision"). Because of the way Geohash are
      # built, the shared Geohash prefix length of two locations will
      # <em>usually</em> increase as the distance between the points decreases.
      # Put another way, the geohashes of two nearby points will
      # <em>usually</em> have a longer shared prefix than two points which are
      # distant from one another.
      #
      # Read more about Geohashes on
      # {Wikipedia}[http://en.wikipedia.org/wiki/Geohash] or play around with
      # generating your own at {geohash.org}[http://geohash.org/].
      #
      # In Sunspot, GeoHashes can have a precision between 3 and 12; this is the
      # number of characters in the hash. The precisions have the following
      # maximum bounding box sizes, in miles:
      #
      # <dt>3</dt>
      # <dd>389.07812</dd>
      # <dt>4</dt>
      # <dd>97.26953</dd>
      # <dt>5</dt>
      # <dd>24.31738</dd>
      # <dt>6</dt>
      # <dd>6.07935</dd>
      # <dt>7</dt>
      # <dd>1.51984
      # <dt>8</dt>
      # <dd>0.37996</dd>
      # <dt>9</dt>
      # <dd>0.09499</dd>
      # <dt>10</dt>
      # <dd>0.02375</dd>
      # <dt>11</dt>
      # <dd>0.00594</dd>
      # <dt>12</dt>
      # <dd>0.00148</dd>
      #
      # ==== Score, boost, and sorting with location search
      #
      # The concept of relevance scoring is a familiar one from fulltext search;
      # Solr (or Lucene, actually) gives each result document a score based on
      # how relevant the document's text is to the search phrase. Sunspot's
      # location search also uses scoring to determine geographical relevance;
      # using boosts, longer prefix matches (which are, in general,
      # geographically closer to the search origin) are assigned higher
      # relevance. This means that the results of a pure location search are
      # <em>roughly</em> in order of geographical distance, as long as no other
      # sort is specified explicitly.
      #
      # This geographical relevance plays on the same field as fulltext scoring;
      # if you use both fulltext and geographical components in a single search,
      # both types of relevance will be taken into account when scoring the
      # matches. Thus, a very close fulltext match that's further away from the
      # geographical origin will be scored similarly to a less precise fulltext
      # match that is very close to the geographical origin. That's likely to be
      # consistent with the way most users would expect a fulltext geographical
      # search to work.
      #
      # ==== Options
      #
      # <dt><code>:precision</code></dt>
      # <dd>The minimum precision at which locations should match. See the table
      # of precisions and bounding-box sizes above; the proximity value will
      # ensure that all matching documents share a bounding box of the
      # corresponding maximum size with your origin point. The default value
      # is 7, meaning all results will share a bounding box with edges of
      # about one and a half miles with the origin.</dd>
      # <dt><code>:boost</code></dt>
      # <dd>The boost to apply to maximum-precision matches. Default is 1.0. You
      # can use this option to adjust the weight given to geographic
      # proximity versus fulltext matching, if you are doing both in a
      # search.</dd>
      # <dt><code>:precision_factor</code></dt>
      # <dd>This option determines how much boost is applied to matches at lower
      # precisions. The default value, 16.0, means that a match at precision
      # N is 1/16 as relevant as a match at precision N+1 (this is consistent
      # with the fact that each precision's bounding box is about sixteen
      # times the size of the next highest precision.)</dd>
      #
      # ==== Example
      #
      #   Sunspot.search(Post) do
      #     fulltext('pizza')
      #     with(:location).near(-40.0, -70.0, :boost => 2, :precision => 6)
      #   end
      #
      def near(lat, lng, options = {})
        @query.fulltext.add_location(@field, lat, lng, options)
      end

      #
      # Performs a query that is filtered by a radius around a given
      # latitude and longitude.
      #
      # ==== Parameters
      #
      # :lat<Numeric>::
      #   Latitude (in degrees)
      # :lon<Numeric>::
      #   Longitude (in degrees)
      # :radius<Numeric>::
      #   Radius (in kilometers)
      #
      # ==== Options
      #
      # <dt><code>:bbox</code></dt>
      # <dd>If `true`, performs the search using `bbox`. `bbox` is
      # more performant, but also more inexact (guaranteed to encompass
      # all of the points of interest, but may also include other points
      # that are slightly outside of the required distance).</dd>
      #
      def in_radius(lat, lon, radius, options = {})
        @query.add_geo(Sunspot::Query::Geofilt.new(@field, lat, lon, radius, options))
      end

      #
      # Performs a query that is filtered by a bounding box
      #
      # ==== Parameters
      # 
      # :first_corner<Array>::
      #   First corner (expressed as an array `[latitude, longitude]`)
      # :second_corner<Array>::
      #   Second corner (expressed as an array `[latitude, longitude]`)
      #
      def in_bounding_box(first_corner, second_corner)
        @query.add_geo(Sunspot::Query::Bbox.new(@field, first_corner, second_corner))
      end
    end
  end
end
