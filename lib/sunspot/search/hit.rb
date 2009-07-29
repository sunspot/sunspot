module Sunspot
  class Search
    class Hit
      SPECIAL_KEYS = Set.new(%w(id type score)) #:nodoc:

      # 
      # Primary key of object associated with this hit, as string.
      #
      attr_reader :primary_key
      # 
      # Class name of object associated with this hit, as string.
      #
      attr_reader :class_name
      # 
      # Keyword relevance score associated with this result. Nil if this hit
      # is not from a keyword search.
      #
      attr_reader :score

      attr_writer :instance #:nodoc:

      def initialize(raw_hit, search, highlights = {}) #:nodoc:
        @class_name, @primary_key = *raw_hit['id'].match(/([^ ]+) (.+)/)[1..2]
        @score = raw_hit['score']
        @search = search
        @stored_values = raw_hit
        @stored_cache = {}
        @highlights = []
        if highlights && highlights.include?("#{@class_name} #{@primary_key}")
          highlights["#{@class_name} #{@primary_key}"].each do |highlighted_field|
            @highlights << Highlight.new(highlighted_field.first, highlighted_field.last)
          end
        end
      end
      
      #
      # Returns all highlights for this hit when called without parameters.
      # When a field_name is provided, returns only the highlight for this field.
      #
      def highlights(field_name = nil)
        return @highlights if field_name.nil?
        @highlights.select{ |highlight| highlight.field_name == field_name.to_sym }.first
      end

      # 
      # Retrieve stored field value. For any attribute field configured with
      # :stored => true, the Hit object will contain the stored value for
      # that field. The value of this field will be typecast according to the
      # type of the field.
      #
      # ==== Parameters
      #
      # field_name<Symbol>::
      #   The name of the field for which to retrieve the stored value.
      #
      def stored(field_name)
        @stored_cache[field_name.to_sym] ||=
          begin
            field = Sunspot::Setup.for(@class_name).field(field_name)
            field.cast(@stored_values[field.indexed_name])
          end
      end

      # 
      # Retrieve the instance associated with this hit. This is lazy-loaded, but
      # the first time it is called on any hit, all the hits for the search will
      # load their instances using the adapter's #load_all method.
      #
      def instance
        if @instance.nil?
          @search.populate_hits!
        end
        @instance
      end
    end
  end
end
