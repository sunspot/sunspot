module SunspotRails
  module Generators
    class Base < Rails::Generators::NamedBase
      def self.source_root
        @_sunspot_rails_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'sunspot_rails', generator_name, 'templates'))
      end
    end
  end
end
