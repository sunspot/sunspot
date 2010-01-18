require 'erb'

module Sunspot
  # 
  # Object that encapsulates schema information for building a Solr schema.xml
  # file. This class is used by the schema:compile task as well as the
  # sunspot-configure-solr executable.
  #
  class Schema #:nodoc:all
    FieldType = Struct.new(:name, :class_name, :suffix)
    FieldVariant = Struct.new(:attribute, :suffix)

    DEFAULT_TOKENIZER = 'solr.StandardTokenizerFactory'
    DEFAULT_FILTERS = %w(solr.StandardFilterFactory solr.LowerCaseFilterFactory)

    FIELD_TYPES = [
      FieldType.new('boolean', 'Bool', 'b'),
      FieldType.new('sfloat', 'SortableFloat', 'f'),
      FieldType.new('date', 'Date', 'd'),
      FieldType.new('sint', 'SortableInt', 'i'),
      FieldType.new('string', 'Str', 's'),
      FieldType.new('sdouble', 'SortableDouble', 'e'),
      FieldType.new('slong', 'SortableLong', 'l'),
      FieldType.new('tint', 'TrieInteger', 'it'),
      FieldType.new('tfloat', 'TrieFloat', 'ft'),
      FieldType.new('tdate', 'TrieInt', 'dt')

    ]

    FIELD_VARIANTS = [
      FieldVariant.new('multiValued', 'm'),
      FieldVariant.new('stored', 's')
    ]

    attr_reader :tokenizer, :filters

    def initialize
      @tokenizer = DEFAULT_TOKENIZER
      @filters = DEFAULT_FILTERS.dup
    end

    # 
    # Attribute field types defined in the schema
    #
    def types
      FIELD_TYPES
    end

    # 
    # DynamicField instances representing all the available types and variants
    #
    def dynamic_fields
      fields = []
      variant_combinations.each do |field_variants|
        FIELD_TYPES.each do |type|
          fields << DynamicField.new(type, field_variants)
        end
      end
      fields
    end

    # 
    # Which tokenizer to use for text fields
    #
    def tokenizer=(tokenizer)
      @tokenizer = 
        if tokenizer =~ /\./
          tokenizer
        else
          "solr.#{tokenizer}TokenizerFactory"
        end
    end

    # 
    # Add a filter for text field tokenization
    #
    def add_filter(filter)
      @filters <<
        if filter =~ /\./
          filter
        else
          "solr.#{filter}FilterFactory"
        end
    end

    # 
    # Return an XML representation of this schema using the ERB template
    #
    def to_xml
      template = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'schema.xml.erb')
      ERB.new(File.read(template), nil, '-').result(binding)
    end

    private

    #
    # All of the possible combinations of variants
    #
    def variant_combinations
      combinations = []
      0.upto(2 ** FIELD_VARIANTS.length - 1) do |b|
        combinations << combination = []
        FIELD_VARIANTS.each_with_index do |variant, i|
          combination << variant if b & 1<<i > 0
        end
      end
      combinations
    end

    # 
    # Represents a dynamic field (in the Solr schema sense, not the Sunspot
    # sense).
    #
    class DynamicField
      def initialize(type, field_variants)
        @type, @field_variants = type, field_variants
      end

      # 
      # Name of the field in the schema
      #
      def name
        variant_suffixes = @field_variants.map { |variant| variant.suffix }.join
        "*_#{@type.suffix}#{variant_suffixes}"
      end

      # 
      # Name of the type as defined in the schema
      #
      def type
        @type.name
      end

      # 
      # Implement magic methods to ask if a field is of a particular variant.
      # Returns "true" if the field is of that variant and "false" otherwise.
      #
      def method_missing(name, *args, &block)
        if name.to_s =~ /\?$/ && args.empty?
          if @field_variants.any? { |variant| "#{variant.attribute}?" == name.to_s }
            'true'
          else
            'false'
          end
        else
          super(name.to_sym, *args, &block)
        end
      end
    end
  end
end
