require 'yaml'
require 'rexml/rexml'
require 'rexml/document'
require 'fileutils'

module Sunspot
  class Installer
    # 
    # This class modifies an existing Solr schema.xml file to work with Sunspot.
    # It makes the minimum necessary changes to the schema, adding fields and
    # types only when they don't already exist. It also comments all fields and
    # types that Sunspot needs, whether or not they were preexisting, so that
    # users can modify the resulting schema without unwittingly breaking it.
    #
    class SchemaBuilder
      include TaskHelper

      CONFIG_PATH = File.join(
        File.dirname(__FILE__), '..', '..', '..', 'installer', 'config', 'schema.yml'
      )

      class <<self
        def execute(schema_path, options = {})
          new(schema_path, options).execute
        end
        
        private :new
      end

      def initialize(schema_path, options = {})
        @schema_path = schema_path
        @config = File.open(CONFIG_PATH) { |f| YAML.load(f) }
        @verbose = !!options[:verbose]
        @force = !!options[:force]
      end

      def execute
        if @force
          FileUtils.mkdir_p(File.dirname(@schema_path))
          source_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'solr', 'solr', 'conf', 'schema.xml')
          FileUtils.cp(source_path, @schema_path)
          say("Copied default schema.xml to #{@schema_path}")
        else
          @document = File.open(@schema_path) do |f|
            Nokogiri::XML(
              f, nil, nil,
              Nokogiri::XML::ParseOptions::DEFAULT_XML |
              Nokogiri::XML::ParseOptions::NOBLANKS
            )
          end
          @root = @document.root
          @added_types = Set[]
          add_fixed_fields
          add_dynamic_fields
          set_misc_settings
          original_path = "#{@schema_path}.orig"
          FileUtils.cp(@schema_path, original_path)
          say("Saved backup of original to #{original_path}")
          File.open(@schema_path, 'w') do |file|
            @document.write_xml_to(file, :indent => 2)
          end
          say("Wrote schema to #{@schema_path}")
        end
      end

      private

      def add_fixed_fields
        @config['fixed'].each do |name, options|
          maybe_add_field(name, options['type'], :indexed, *Array(options['attributes']))
        end
      end

      def add_dynamic_fields
        @config['types'].each do |type, options|
          if suffix = options['suffix']
            variant_combinations(options).each do |variants|
              variants_suffix = variants.map { |variant| variant[1] || '' }.join
              maybe_add_field("*_#{suffix}#{variants_suffix}", type, *variants.map { |variant| variant[0] })
            end
          end
        end
      end

      def maybe_add_field(name, type, *flags)
        node_name = name =~ /\*/ ? 'dynamicField' : 'field'
        if field_node = fields_node.xpath(%Q(#{node_name}[@name="#{name}"])).first
          say("Using existing #{node_name} #{name.inspect}")
          add_comment(field_node)
          return
        end
        maybe_add_type(type)
        say("Adding field #{name.inspect}")
        attributes = {
          'name' => name,
          'type' => type,
          'indexed' => 'true',
          'stored' => 'false',
          'multiValued' => 'false'
        }
        flags.each do |flag|
          attributes[flag.to_s] = 'true'
        end
        field_node = add_element(fields_node, node_name, attributes)
        add_comment(field_node)
      end

      def maybe_add_type(type)
        unless @added_types.include?(type)
          @added_types << type
          if type_node = types_node.xpath(%Q(fieldType[@name="#{type}"])).first ||
             types_node.xpath(%Q(fieldtype[@name="#{type}"])).first
            say("Using existing type #{type.inspect}")
            add_comment(type_node)
            return
          end
          say("Adding type #{type.inspect}")
          type_config = @config['types'][type]
          type_node = add_element(
            types_node,
            'fieldType',
            'name' => type,
            'class' => to_solr_class(type_config['class']),
            'omitNorms' => type_config['omit_norms'].nil? ? 'true' : type_config['omit_norms'].to_s
          )
          if type_config['tokenizer']
            add_analyzer(type_node, type_config)
          end
          add_comment(type_node)
        end
      end

      def add_analyzer(node, config)
        analyzer_node = add_element(node, 'analyzer')
        add_element(
          analyzer_node,
          'tokenizer',
          'class' => to_solr_class(config['tokenizer'])
        )
        Array(config['filters']).each do |filter|
          add_element(analyzer_node, 'filter', 'class' => to_solr_class(filter))
        end
      end

      def set_misc_settings
        if @root.xpath('uniqueKey[normalize-space()="id"]').any?
          say('Unique key already set')
        else
          say("Creating unique key node")
          add_element(@root, 'uniqueKey').content = 'id'
        end
        say('Setting default operator to AND')
        solr_query_parser_node = @root.xpath('solrQueryParser').first ||
                                 add_element(@root, 'solrQueryParser')
        solr_query_parser_node['defaultOperator'] = 'AND'
      end

      def add_comment(node)
        comment_message = " *** This #{node.name} is used by Sunspot! *** "
        unless (comment = previous_non_text_sibling(node)) && comment.comment? && comment.content =~ /Sunspot/
          node.add_previous_sibling(Nokogiri::XML::Comment.new(@document, comment_message))
        end
      end

      def types_node
        @types_node ||= @root.xpath('/schema/types').first
      end

      def fields_node
        @fields_node ||= @root.xpath('/schema/fields').first
      end

      def to_solr_class(class_name)
        if class_name =~ /\./
          class_name
        else
          "solr.#{class_name}"
        end
      end

      def previous_non_text_sibling(node)
        if previous_sibling = node.previous_sibling
          if previous_sibling.node_type == :text
            previous_non_text_sibling(previous_sibling)
          else
            previous_sibling
          end
        end
      end

      #
      # All of the possible combinations of variants
      #
      def variant_combinations(type_options)
        invariants = type_options['invariants'] || {}
        combinations = []
        variants = @config['variants'].reject { |name, suffix| invariants.has_key?(name) }
        0.upto(2 ** variants.length - 1) do |b|
          combinations << combination = []
          variants.each_with_index do |variant, i|
            combination << variant if b & 1<<i > 0
          end
          invariants.each do |name, value|
            if value
              combination << [name]
            end
          end
        end
        combinations
      end

      def say(message)
        if @verbose
          STDOUT.puts(message)
        end
      end
    end
  end
end
