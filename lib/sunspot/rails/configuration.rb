module Sunspot
  module Rails
    class Configuration
      attr_writer :hostname, :port

      def hostname
        @hostname ||= 
          if user_configuration.has_key?('solr')
            user_configuration['solr']['hostname']
          end || 'localhost'
      end

      def port
        @port ||=
          if user_configuration.has_key?('solr')
            user_configuration['solr']['port']
          end || 8983
      end

      private

      def user_configuration
        @user_configuration ||=
          begin
            path = File.join(::Rails.root, 'config', 'sunspot.yml')
            if File.exist?(path)
              File.open(path) do |file|
                YAML.load(file)[::Rails.env]
              end
            end
          end
      end
    end
  end
end
