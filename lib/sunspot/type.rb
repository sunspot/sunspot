module Sunspot
  module Type
    module TextType
      class <<self
        def indexed_name(name)
        "#{name}_text"
        end

        def to_indexed(value)
          value.to_s if value
        end
      end
    end

    module StringType
      class <<self
        def indexed_name(name)
        "#{name}_s"
        end

        def to_indexed(value)
          value.to_s if value
        end

        def cast(string)
          string
        end
      end
    end

    module IntegerType
      class <<self
        def indexed_name(name)
        "#{name}_i"
        end

        def to_indexed(value)
          value.to_i.to_s if value
        end

        def cast(string)
          string.to_i
        end
      end
    end

    module FloatType
      class <<self
        def indexed_name(name)
        "#{name}_f"
        end

        def to_indexed(value)
          value.to_f.to_s if value
        end

        def cast(string)
          string.to_f
        end
      end
    end

    module TimeType
      class <<self
        def indexed_name(name)
        "#{name}_d"
        end

        def to_indexed(value)
          if value
            time = value.respond_to?(:to_time) ? value.to_time : Time.parse(value.to_s)
            time.utc.xmlschema
          end
        end

        def cast(string)
          Time.xmlschema(string)
        end
      end
    end
  end
end
