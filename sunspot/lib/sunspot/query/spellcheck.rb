module Sunspot
  module Query
    class Spellcheck < Connective::Conjunction
      attr_accessor :options

      def initialize(options = {})
        @options = options
      end

      def to_params
        options = {}
        @options.each do |key, val|
          options["spellcheck." + Sunspot::Util.method_case(key.to_s)] = val
        end
        { :spellcheck => true }.merge(options)
      end
    end
  end
end
