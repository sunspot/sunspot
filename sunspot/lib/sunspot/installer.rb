%w(task_helper schema_builder solrconfig_updater).each do |file|
  require File.join(File.dirname(__FILE__), 'installer', file)
end

module Sunspot
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
      SchemaBuilder.execute(
        File.join(@solr_home, 'conf', 'schema.xml'),
        @options
      )
      SolrconfigUpdater.execute(
        File.join(@solr_home, 'conf', 'solrconfig.xml'),
        @options
      )
    end
  end
end
