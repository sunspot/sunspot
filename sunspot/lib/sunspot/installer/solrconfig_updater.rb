require 'rubygems'
require 'fileutils'
require 'nokogiri'

module Sunspot
  class Installer
    class SolrconfigUpdater
      include TaskHelper

      CONFIG_FILES = %w(solrconfig.xml elevate.xml spellings.txt stopwords.txt synonyms.txt)

      class <<self
        def execute(solrconfig_path, options = {})
          new(solrconfig_path, options).execute
        end
      end

      def initialize(solrconfig_path, options)
        @force = !!options[:force]
        @solrconfig_path = solrconfig_path
        @verbose = !!options[:verbose]
      end

      def execute
        config_dir = File.dirname(@solrconfig_path)
        FileUtils.mkdir_p(config_dir)
        solrconfig_existed = File.exists?(@solrconfig_path)
        CONFIG_FILES.each do |file|
          if @force || !File.exists?(File.join(config_dir, file))
            source_path =
              File.join(File.dirname(__FILE__), '..', '..', '..', 'solr_config', file)
            FileUtils.cp(source_path, config_dir)
            say("Copied default #{file} to #{config_dir}")
          end
        end
        if solrconfig_existed && !@force
          @document = File.open(@solrconfig_path) do |f|
            Nokogiri::XML(
              f, nil, nil,
              Nokogiri::XML::ParseOptions::DEFAULT_XML |
              Nokogiri::XML::ParseOptions::NOBLANKS
            )
          end
          @root = @document.root
          maybe_add_more_like_this_handler
          original_path = "#{@solrconfig_path}.orig"
          FileUtils.cp(@solrconfig_path, original_path)
          say("Saved backup of original to #{original_path}")
          File.open(@solrconfig_path, 'w') do |file|
            @document.write_to(
              file,
              :indent => 2
            )
          end
          say("Wrote solrconfig to #{@solrconfig_path}")
        end
      end

      private

      def maybe_add_more_like_this_handler
        unless @root.xpath('requestHandler[@name="/mlt"]').first
          mlt_node = add_element(
            @root, 'requestHandler',
            :name => '/mlt', :class => 'solr.MoreLikeThisHandler'
          )
          defaults_node = add_element(mlt_node, 'lst', :name => 'defaults')
          add_element(defaults_node, 'str', :name => 'mlt.mintf').content = '1'
          add_element(defaults_node, 'str', :name => 'mlt.mindf').content = '2'
        end
      end
    end
  end
end
