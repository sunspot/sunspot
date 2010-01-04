require 'fileutils'

module Sunspot
  class Installer
    class LibraryInstaller
      class <<self
        def execute(library_path, options)
          new(library_path, options).execute
        end
      end

      def initialize(library_path, options)
        @library_path = library_path
        @verbose = !!options[:verbose]
        @force = !!options[:force]
      end

      def execute
        sunspot_library_path = File.join(File.dirname(__FILE__), '..', '..',
                                         '..', 'solr', 'solr', 'lib')
        return if File.expand_path(sunspot_library_path) == File.expand_path(@library_path)
        FileUtils.mkdir_p(@library_path)
        Dir.glob(File.join(sunspot_library_path, '*.jar')).each do |jar|
          jar = File.expand_path(jar)
          dest = File.join(@library_path, File.basename(jar))
          if File.exist?(dest)
            if @force
              say("Removing existing library #{dest}")
            else
              next
            end
          end
          say("Copying #{jar} => #{dest}")
          FileUtils.cp(jar, dest)
                           end
      end

      def say(message)
        if @verbose
          STDOUT.puts(message)
        end
      end
    end
  end
end
