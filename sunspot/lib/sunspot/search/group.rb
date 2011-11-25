module Sunspot
  module Search
    class Group
      attr_reader :value

      def initialize(value, doclist, search)
        @value, @doclist, @search = value, doclist, search
      end

      def hits
        @hits ||= @doclist['docs'].map do |doc|
          # TODO: Can highlighting work here?
          Hit.new(doc, nil, @search)
        end
      end
    end
  end
end
