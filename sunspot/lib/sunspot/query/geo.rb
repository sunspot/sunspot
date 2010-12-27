begin
  require 'geohash'
rescue LoadError => e
  require 'pr_geohash'
end

module Sunspot
  module Query
    class Geo
      MAX_PRECISION = 12
      NEIGHBOR_PRECISION = 7 # don't include neighbors above this precision
      DEFAULT_PRECISION = 2
      DEFAULT_PRECISION_FACTOR = 16.0

      def initialize(field, lat, lng, options)
        @field, @options = field, options
        @geohash = GeoHash.encode(lat.to_f, lng.to_f, MAX_PRECISION)
      end

      def to_params
        { :q => to_boolean_query }
      end

      def to_subquery
        "(#{to_boolean_query})"
      end

      private

      def to_boolean_query
        queries = []
        geohashes = {}

        # generate decreasingly-precise geohashes, with adjacent neighbors
        MAX_PRECISION.downto(precision) do |i|
          geohashes[i] = [@geohash[0, i]]
          if i <= NEIGHBOR_PRECISION
            neighbors = GeoHash.neighbors(@geohash[0, i + 1])
            geohashes[i] = geohashes[i] + neighbors.reject{ |hash| hash[0, i] =~ %r{^@geohash[0, i]} }
          end
        end
        
        # turn our geohashes into boosted query clauses
        geohashes.keys.each do |p|
          geohashes[p].each do |geohash|
            star = p == MAX_PRECISION ? '' : '*'
            pb = precision_boost(boost, precision_factor, p)
            queries << "#{@field.indexed_name}:#{geohash}#{star}^#{pb}"
          end
        end

        queries.join(' OR ')
      end
      
      def precision_boost(boost, precision_factor, precision)
        f = boost * precision_factor ** (precision-MAX_PRECISION).to_f
        Util.format_float(f, 3)
      end
      
      def precision
        @options[:precision] || DEFAULT_PRECISION
      end

      def precision_factor
        @options[:precision_factor] || DEFAULT_PRECISION_FACTOR
      end

      def boost
        @options[:boost] || 1.0
      end
    end
  end
end

if __FILE__ == $0
  require 'spec'
  require File.join(File.dirname(__FILE__), "../../sunspot.rb")

  describe "geo queries" do
    
    before(:all) do
      @mock_field = mock(
        "test location field",
        :indexed_name => "test_location_s"
      )
    end
    
    it "should include neighbors in its boolean subquery" do
      geo_query = Sunspot::Query::Geo.new(
        @mock_field,
        32.7153292, -117.1572551,
        :precision => 2
      )
      geo_query.to_subquery.scan(/test_location_s/).length.should == 23
    end
    
    # TODO: capture ordering assertions to avoid egregios regressions
    # - generate a list of sample coordinates
    # - pre-compute their distance from a specific search point
    # - insert the documents into Solr
    # - perform the search
    # - assert a correct (rough) ordering
    
  end
  
  exit ::Spec::Runner::CommandLine.run
end