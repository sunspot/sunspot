require "fileutils"
require "pathname"

module Sunspot
  module Solr
    class Installer
      class <<self
        def execute(solr_home, options = {})
          new(Pathname(solr_home).expand_path, options).execute
        end
      end

      attr_reader :config_path, :options

      class << self
        def execute(config_path, options = {})
          new(config_path, options).execute
        end
      end

      def initialize(config_path, options)
        @config_path = config_path
        @options     = options
      end

      def force?
        !!@options[:force]
      end

      def verbose?
        !!@options[:verbose]
      end

      def execute
        return if sunspot_config_path == config_path

        config_source_files.each do |source_path|
          destination_path = get_destination_path(source_path)

          if destination_path.exist?
            next unless force?
            output "Removing existing file #{ destination_path }"
          end

          destination_dir = destination_path.dirname
          unless destination_dir.exist?
            output "Creating directory #{ destination_dir }"
            destination_dir.mkpath
          end

          output "Copying #{ source_path } => #{ destination_path }"
          FileUtils.copy(source_path, destination_path)
        end
      end

      def sunspot_config_path
        @sunspot_config_path ||= Pathname(__FILE__).join("../../../../solr/solr")
      end

      def config_source_files
        @config_source_files ||= glob_source_files
      end

      private

      def get_destination_path(source_path)
        source_path.sub(sunspot_config_path.to_s, config_path.to_s)
      end

      def glob_source_files
        source_files = []
        source_files += Pathname.glob(sunspot_config_path.join("solr.xml"))
        source_files += Pathname.glob(sunspot_config_path.join("configsets/**/*"))
        source_files += Pathname.glob(sunspot_config_path.join("**/core.properties"))
        source_files.select(&:file?).map(&:expand_path)
      end

      def output message
        STDOUT.puts(message) if verbose?
      end
    end
  end
end
