module Sunspot
  module Type
    TextType = Module.new
    StringType = Module.new
    IntegerType = Module.new
    FloatType = Module.new
    TimeType = Module.new

    class <<TextType
      def indexed_name(name)
        "#{name}_text"
      end

      def to_indexed(value)
        value.to_s if value
      end
    end

    class <<StringType
      def indexed_name(name)
        "#{name}_s"
      end

      def to_indexed(value)
        value.to_s if value
      end
    end

    class <<IntegerType
      def indexed_name(name)
        "#{name}_i"
      end

      def to_indexed(value)
        value.to_i.to_s if value
      end
    end

    class <<FloatType
      def indexed_name(name)
        "#{name}_f"
      end

      def to_indexed(value)
        value.to_f.to_s if value
      end
    end

    class <<TimeType
      def indexed_name(name)
        "#{name}_d"
      end

      def to_indexed(value)
        if value
          time = if value.respond_to?(:to_time)
            value.to_time
          else
            Time.parse(value.to_s)
          end
          time.utc.strftime('%FT%TZ')
        end
      end
    end
  end
end
