require 'singleton'
begin
  require 'geohash'
rescue LoadError
  require 'pr_geohash'
end

module Sunspot
  # 
  # This module contains singleton objects that represent the types that can be
  # indexed and searched using Sunspot. Plugin developers should be able to
  # add new constants to the Type module; as long as they implement the
  # appropriate methods, Sunspot should be able to integrate them (note that
  # this capability is untested at the moment). The required methods are:
  #
  # +indexed_name+::
  #   Convert a given field name into its form as stored in Solr. This
  #   generally means adding a suffix to match a Solr dynamicField definition.
  # +to_indexed+::
  #   Convert a value of this type into the appropriate Solr string
  #   representation.
  # +cast+::
  #   Convert a Solr string representation of a value into the appropriate
  #   Ruby type.
  #
  module Type
    class <<self
      def register(sunspot_type, *classes)
        classes.each do |clazz|
          ruby_type_map[clazz.name.to_sym] = sunspot_type.instance
        end
      end

      def for_class(clazz)
        if clazz
          ruby_type_map[clazz.name.to_sym] || for_class(clazz.superclass)
        end
      end

      def for(object)
        for_class(object.class)
      end

      def to_indexed(object)
        if type = self.for(object)
          type.to_indexed(object)
        else
          object.to_s
        end
      end

      def to_literal(object)
        if type = self.for(object)
          type.to_literal(object)
        else
          raise ArgumentError, "Can't use #{object.inspect} as Solr literal: #{object.class} has no registered Solr type"
        end
      end

      private

      def ruby_type_map
        @ruby_type_map ||= {}
      end
    end

    class AbstractType #:nodoc:
      include Singleton

      def accepts_dynamic?
        true
      end

      def accepts_more_like_this?
        false
      end

      def to_literal(object)
        raise(
          ArgumentError,
          "#{self.class.name} cannot be used as a Solr literal"
        )
      end
    end

    # 
    # Text is a special type that stores data for fulltext search. Unlike other
    # types, Text fields are tokenized and are made available to the keyword
    # search phrase. Text fields cannot be faceted, ordered upon, or used in
    # restrictions. Similarly, text fields are the only fields that are made
    # available to keyword search.
    #
    class TextType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_text"
      end

      def to_indexed(value) #:nodoc:
        value.to_s if value
      end

      def cast(text)
        text
      end

      def accepts_dynamic?
        false
      end

      def accepts_more_like_this?
        true
      end
    end

    # 
    # The String type represents string data.
    #
    class StringType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_s"
      end

      def to_indexed(value) #:nodoc:
        value.to_s if value
      end

      def cast(string) #:nodoc:
        string
      end
    end
    register(StringType, String)

    # 
    # The Integer type represents integers.
    #
    class IntegerType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_i"
      end

      def to_indexed(value) #:nodoc:
        value.to_i.to_s if value
      end

      def to_literal(value)
        to_indexed(value)
      end

      def cast(string) #:nodoc:
        string.to_i
      end
    end
    register(IntegerType, Integer)

    # 
    # The Long type indexes Ruby Fixnum and Bignum numbers into Java Longs
    #
    class LongType < IntegerType
      def indexed_name(name) #:nodoc:
        "#{name}_l"
      end
    end

    # 
    # The Float type represents floating-point numbers.
    #
    class FloatType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_f"
      end

      def to_indexed(value) #:nodoc:
        value.to_f.to_s if value
      end

      def to_literal(value)
        to_indexed(value)
      end

      def cast(string) #:nodoc:
        string.to_f
      end
    end
    register(FloatType, Float)

    # 
    # The Double type indexes Ruby Floats (which are in fact doubles) into Java
    # Double fields
    #
    class DoubleType < FloatType
      def indexed_name(name)
        "#{name}_e"
      end
    end

    # 
    # The time type represents times. Note that times are always converted to
    # UTC before indexing, and facets of Time fields always return times in UTC.
    #
    class TimeType < AbstractType
      XMLSCHEMA = "%Y-%m-%dT%H:%M:%SZ"

      def indexed_name(name) #:nodoc:
        "#{name}_d"
      end

      def to_indexed(value) #:nodoc:
        if value
          value_to_utc_time(value).strftime(XMLSCHEMA)
        end
      end

      def to_literal(value)
        to_indexed(value)
      end

      def cast(string) #:nodoc:
        begin
          Time.xmlschema(string)
        rescue ArgumentError
          DateTime.strptime(string, XMLSCHEMA)
        end
      end

      private

      def value_to_utc_time(value)
        if value.respond_to?(:utc)
          value.utc
        elsif value.respond_to?(:new_offset)
          value.new_offset
        else
          begin
            Time.parse(value.to_s).utc
          rescue ArgumentError
            DateTime.parse(value.to_s).new_offset
          end
        end
      end
    end
    register TimeType, Time, DateTime

    # 
    # The DateType encapsulates dates (without time information). Internally,
    # Solr does not have a date-only type, so this type indexes data using
    # Solr's DateField type (which is actually date/time), midnight UTC of the
    # indexed date.
    #
    class DateType < TimeType
      def to_indexed(value) #:nodoc:
        if value
          time = 
            if %w(year mon mday).all? { |method| value.respond_to?(method) }
              Time.utc(value.year, value.mon, value.mday)
            else
              date = Date.parse(value.to_s)
              Time.utc(date.year, date.mon, date.mday)
            end
          super(time)
        end
      end

      def cast(string) #:nodoc:
        time = super
        Date.civil(time.year, time.mon, time.mday)
      end
    end
    register DateType, Date

    # 
    # Store integers in a TrieField, which makes range queries much faster.
    #
    class TrieIntegerType < IntegerType
      def indexed_name(name)
        "#{super}t"
      end
    end

    # 
    # Store floats in a TrieField, which makes range queries much faster.
    #
    class TrieFloatType < FloatType
      def indexed_name(name)
        "#{super}t"
      end
    end

    # 
    # Index times using a TrieField. Internally, trie times are indexed as
    # Unix timestamps in a trie integer field, as TrieField does not support
    # datetime types natively. This distinction should have no effect from the
    # standpoint of the library's API.
    #
    class TrieTimeType < TimeType
      def indexed_name(name)
        "#{super}t"
      end
    end


    # 
    # The boolean type represents true/false values. Note that +nil+ will not be
    # indexed at all; only +false+ will be indexed with a false value.
    #
    class BooleanType < AbstractType
      def indexed_name(name) #:nodoc:
        "#{name}_b"
      end

      def to_indexed(value) #:nodoc:
        unless value.nil?
          value ? 'true' : 'false'
        end
      end

      def cast(string) #:nodoc:
        case string
        when 'true'
          true
        when 'false'
          false
        when true, false
          string
        end
      end
    end
    register BooleanType, TrueClass, FalseClass

    # 
    # The Location type encodes geographical coordinates as a GeoHash.
    # The data for this type must respond to the `lat` and `lng` methods; you
    # can use Sunspot::Util::Coordinates as a wrapper if your source data does
    # not follow this API.
    #
    # Location fields are most usefully searched using the
    # Sunspot::DSL::RestrictionWithType#near method; see that method for more
    # information on geographical search.
    #
    # ==== Example
    #
    #   Sunspot.setup(Post) do
    #     location :coordinates do
    #       Sunspot::Util::Coordinates.new(coordinates[0], coordinates[1])
    #     end
    #   end
    #
    class LocationType < AbstractType
      def indexed_name(name)
        "#{name}_s"
      end

      def to_indexed(value)
        GeoHash.encode(value.lat.to_f, value.lng.to_f, 12)
      end
    end

    # 
    # The Latlon type encodes geographical coordinates in the native
    # Solr LatLonType.
    #
    # The data for this type must respond to the `lat` and `lng` methods; you
    # can use Sunspot::Util::Coordinates as a wrapper if your source data does
    # not follow this API.
    #
    # Location fields can be used with the geospatial DSL. See the
    # Geospatial section of the README for examples.
    #
    class LatlonType < AbstractType
      def indexed_name(name)
        "#{name}_ll"
      end

      def to_indexed(value)
        "#{value.lat.to_f},#{value.lng.to_f}"
      end
    end

    class ClassType < AbstractType
      def indexed_name(name) #:nodoc:
        'class_name'
      end

      def to_indexed(value) #:nodoc:
        value.name
      end

      def cast(string) #:nodoc:
        Sunspot::Util.full_const_get(string)
      end
    end
    register ClassType, Class
  end
end
