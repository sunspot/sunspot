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
    # 
    # Text is a special type that stores data for fulltext search. Unlike other
    # types, Text fields are tokenized and are made available to the keyword
    # search phrase. Text fields cannot be faceted, ordered upon, or used in
    # restrictions. Similarly, text fields are the only fields that are made
    # available to keyword search.
    #
    module TextType
      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_text"
        end

        def to_indexed(value) #:nodoc:
          value.to_s if value
        end

        def cast(text)
          text
        end
      end
    end

    # 
    # The String type represents string data.
    #
    module StringType
      class <<self
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
    end

    # 
    # The Integer type represents integers.
    #
    module IntegerType
      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_i"
        end

        def to_indexed(value) #:nodoc:
          value.to_i.to_s if value
        end

        def cast(string) #:nodoc:
          string.to_i
        end
      end
    end

    # 
    # The Float type represents floating-point numbers.
    #
    module FloatType
      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_f"
        end

        def to_indexed(value) #:nodoc:
          value.to_f.to_s if value
        end

        def cast(string) #:nodoc:
          string.to_f
        end
      end
    end

    # 
    # The time type represents times. Note that times are always converted to
    # UTC before indexing, and facets of Time fields always return times in UTC.
    #
    module TimeType

      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_d"
        end

        def to_indexed(value) #:nodoc:
          if value
            time =
              if value.respond_to?(:utc)
                value
              else
                Time.parse(value.to_s)
              end
            time.utc.xmlschema
          end
        end

        def cast(string) #:nodoc:
          Time.xmlschema(string)
        end
      end
    end

    # 
    # The DateType encapsulates dates (without time information). Internally,
    # Solr does not have a date-only type, so this type indexes data using
    # Solr's DateField type (which is actually date/time), midnight UTC of the
    # indexed date.
    #
    module DateType
      class <<self
        def indexed_name(name) #:nodoc:
          "#{name}_d"
        end

        def to_indexed(value) #:nodoc:
          if value
            time = 
              if %w(year mon mday).all? { |method| value.respond_to?(method) }
                Time.utc(value.year, value.mon, value.mday)
              else
                date = Date.parse(value.to_s)
                Time.utc(date.year, date.mon, date.mday)
              end
            time.utc.xmlschema
          end
        end

        def cast(string) #:nodoc:
          time = Time.xmlschema(string)
          Date.civil(time.year, time.mon, time.mday)
        end
      end
    end

    # 
    # The boolean type represents true/false values. Note that +nil+ will not be
    # indexed at all; only +false+ will be indexed with a false value.
    #
    module BooleanType
      class <<self
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
          end
        end
      end
    end

    module ClassType
      class <<self
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
    end
  end
end
