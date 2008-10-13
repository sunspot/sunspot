module Sunspot
  module Type
    StringType = Module.new

    class <<StringType
      def indexed_name(name)
        "#{name}_s"
      end

      def to_indexed(value)
        value.to_s if value
      end
    end
  end
end
