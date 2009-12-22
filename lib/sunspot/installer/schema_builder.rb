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
        @verbose = !!options.delete(:verbose)
        @force = !!options.delete(:force)
      end

      def execute
        @document = File.open(@schema_path) { |f| REXML::Document.new(f) }
        @root = @document.root
        @added_types = Set[]
        add_fixed_fields
        add_dynamic_fields
        set_misc_settings
        original_path = "#{@schema_path}.orig"
        FileUtils.cp(@schema_path, original_path)
        say("Saved backup of original to #{original_path}")
        File.open(@schema_path, 'w') { |file| @document.write(file, 2) }
        say("Wrote schema to #{@schema_path}")
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
        if field_node = fields_node.elements[%Q(#{node_name}[@name="#{name}"])]
          if @force
            say("Removing existing #{node_name} #{name.inspect}")
            field_node.remove
          else
            say("Using existing #{node_name} #{name.inspect}")
            add_comment(field_node)
            return
          end
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
        if name == 'type'
          require 'rubygems'
          require 'ruby-debug'
        end
        field_node = fields_node.add_element(node_name, attributes)
        add_comment(field_node)
      end

      def maybe_add_type(type)
        unless @added_types.include?(type)
          @added_types << type
          if type_node = types_node.elements[%Q(fieldType[@name="#{type}"])] || types_node.elements[%Q(fieldtype[@name="#{type}"])]
            if @force
              say("Removing type #{type.inspect}")
              type_node.remove
            else
              say("Using existing type #{type.inspect}")
              add_comment(type_node)
              return
            end
          end
          say("Adding type #{type.inspect}")
          type_config = @config['types'][type]
          type_node = types_node.add_element(
            'fieldType',
            'name' => type,
            'class' => to_solr_class(type_config['class']),
            'omitNorms' => type_config['omit_norms'].nil? ? 'true' : type_config['omit_norms']
          )
          if type_config['tokenizer']
            add_analyzer(type_node, type_config)
          end
          add_comment(type_node)
        end
      end

      def add_analyzer(node, config)
        analyzer_node = node.add_element('analyzer')
        analyzer_node.add_element(
          'tokenizer',
          'class' => to_solr_class(config['tokenizer'])
        )
        Array(config['filters']).each do |filter|
          analyzer_node.add_element('filter', 'class' => to_solr_class(filter))
        end
      end

      def set_misc_settings
        unless @root.elements['uniqueKey[text()="id"]']
          unique_key_node = @root.add_element('uniqueKey')
          unique_key_node.add_text('id')
        end
        solr_query_parser_node = @root.elements['solrQueryParser'] || @root.add_element('solrQueryParser')
        solr_query_parser_node.add_attribute('defaultOperator', 'AND')
      end

      def add_comment(node)
        comment_message = " *** This #{node.name} is used by Sunspot! *** "
        unless (comment = previous_non_text_sibling(node)) && comment.node_type == :comment && comment.string =~ /Sunspot/
          node.parent.insert_before(node, REXML::Comment.new(comment_message))
        end
      end

      def types_node
        @types_node ||= @root.elements['/schema/types']
      end

      def fields_node
        @fields_node ||= @root.elements['/schema/fields']
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
