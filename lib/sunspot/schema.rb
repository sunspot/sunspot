using_rubygems = false
begin
  require 'haml'
rescue LoadError => e
  if using_rubygems
    raise(e)
  else
    using_rubygems = true
    require 'rubygems'
    retry
  end
end

module Sunspot
  class Schema
    FieldType = Struct.new(:name, :class_name, :suffix)
    FieldVariant = Struct.new(:attribute, :suffix)

    DEFAULT_TOKENIZER = 'solr.StandardTokenizerFactory'
    DEFAULT_FILTERS = %w(solr.StandardFilterFactory solr.LowerCaseFilterFactory)

    FIELD_TYPES = [
      FieldType.new('boolean', 'Bool', 'b'),
      FieldType.new('sfloat', 'SortableFloat', 'f'),
      FieldType.new('date', 'Date', 'd'),
      FieldType.new('sint', 'SortableInt', 'i'),
      FieldType.new('string', 'Str', 's')
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

    def types
      FIELD_TYPES
    end

    def dynamic_fields
      fields = []
      for field_variants in variant_combinations
        for type in FIELD_TYPES
          fields << DynamicField.new(type, field_variants)
        end
      end
      fields
    end

    def tokenizer=(tokenizer)
      @tokenizer = 
        if tokenizer =~ /\./
          tokenizer
        else
          "solr.#{tokenizer}TokenizerFactory"
        end
    end

    def add_filter(filter)
      @filters <<
        if filter =~ /\./
          filter
        else
          "solr.#{filter}FilterFactory"
        end
    end

    def to_xml
      template = File.read(
        File.join(
          File.dirname(__FILE__),
          '..',
          '..',
          'templates',
          'schema.xml.haml'
        )
      )
      engine = Haml::Engine.new(template)
      engine.render(Object.new, :schema => self)
    end

    private

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

    class DynamicField
      def initialize(type, field_variants)
        @type, @field_variants = type, field_variants
      end

      def name
        variant_suffixes = @field_variants.map { |variant| variant.suffix }.join
        "*_#{@type.suffix}#{variant_suffixes}"
      end

      def type
        @type.name
      end

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
