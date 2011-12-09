require 'fileutils'

module Sunspot
  module Solr
    class Installer
      class ConfigInstaller
        include TaskHelper

        class <<self
          def execute(config_path, options = {})
            new(config_path, options).execute
          end
        end

        def initialize(config_path, options)
          @config_path = config_path
          @verbose = !!options[:verbose]
          @force   = !!options[:force]
        end

        def execute
          sunspot_config_path = File.join(File.dirname(__FILE__), '..', '..',
                                          '..', '..', 'solr', 'solr', 'conf')
          return if File.expand_path(sunspot_config_path) == File.expand_path(@config_path)

          FileUtils.mkdir_p(@config_path)
          Dir.glob(File.join(sunspot_config_path, '*.*')).each do |file|
            file = File.expand_path(file)
            dest = File.join(@config_path, File.basename(file))

            if File.exist?(dest)
              if @force
                say("Removing existing file #{dest}")
              else
                next
              end
            end

            say("Copying #{file} => #{dest}")
            FileUtils.cp(file, dest)
          end
        end
      end
    end
  end
end
