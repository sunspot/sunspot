require 'fileutils'
require 'rake/file_list'

module Sunspot
  module Solr
    class Installer
      class ConfigInstaller
        include TaskHelper
        include FileUtils

        attr_accessor :config_path, :force
        alias_method :force?, :force

        class <<self
          def execute(config_path, options = {})
            new(config_path, options).execute
          end
        end

        def initialize(config_path, options)
          self.config_path = File.expand_path config_path
          self.force   = !!options[:force]
          @verbose = !!options[:verbose]
        end

        def execute
          return if sunspot_config_path == config_path

          sunspot_config_files do |file, dest|
            if File.exist?(dest)
              next unless force?
              say("Removing existing file #{dest}")
            end

            dir = dest.pathmap('%d')
            unless File.exist?(dir)
              say("Creating directory #{dir}")
              mkdir_p dir
            end

            next if File.directory? file

            say("Copying #{file} => #{dest}")
            cp(file, dest)
          end
        end

        private

        def sunspot_config_files(&blk)
          src, dest = expand_files(config_source_files), expand_files(config_dest_files)
          src.zip(dest).each(&blk)
        end

        def config_dest_files
          @config_dest_files ||= config_source_files.pathmap("%{^#{sunspot_config_path},#{config_path}}p")
        end

        def config_source_files
          @config_source_files ||= glob_source_files
        end

        def glob_source_files
          list = Rake::FileList.new("#{sunspot_config_path}/**/*") do |fl| 
            fl.include "#{sunspot_config_path}/../solr.xml", "#{sunspot_config_path}/../**/core.properties"
          end

          list.map! { |path| path.first(2) == '..' ? File.join(sunspot_config_path, path) : path }

          list
        end

        def sunspot_config_path
          @sunspot_config_path ||= File.expand_path sunspot_relative_config_path
        end

        def sunspot_relative_config_path
          File.join File.dirname(__FILE__), '..', '..', '..', '..', 'solr', 'solr', 'configsets'
        end

        def expand_files(filelist)
          filelist.map { |file| File.expand_path file }
        end
      end
    end
  end
end
