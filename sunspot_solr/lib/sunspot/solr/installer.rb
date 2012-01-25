%w(task_helper config_installer).each do |file|
  require File.join(File.dirname(__FILE__), 'installer', file)
end

module Sunspot
  module Solr
    class Installer
      class <<self
        def execute(solr_home, options = {})
          new(solr_home, options).execute
        end

        private :new
      end

      def initialize(solr_home, options)
        @solr_home, @options = solr_home, options
      end

      def execute
        ConfigInstaller.execute(File.join(@solr_home, 'conf'), @options)
      end
    end
  end
end
