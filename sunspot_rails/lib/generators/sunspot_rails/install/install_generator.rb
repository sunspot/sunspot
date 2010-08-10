module SunspotRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end
      def copy_config_file
        template 'config/sunspot.yml'
      end
    end
  end
end

