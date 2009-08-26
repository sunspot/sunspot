module Sunspot #:nodoc:
  module Rails #:nodoc:
    #
    # Sunspot::Rails is configured via the config/sunspot.yml file, which
    # contains properties keyed by environment name. A sample sunspot.yml file
    # would look like:
    #
    #   development:
    #     solr:
    #       hostname: localhost
    #       port: 8982
    #   test:
    #     solr:
    #       hostname: localhost
    #       port: 8983
    #
    #   production:
    #     solr:
    #       hostname: localhost
    #       port: 8983
    #       path: /solr/myindex
    #
    # Sunspot::Rails uses the configuration to set up the Solr connection, as
    # well as for starting Solr with the appropriate port using the
    # <code>rake sunspot:solr:start</code> task.
    #
    class Configuration
      #
      # The host name at which to connect to Solr. Default 'localhost'.
      #
      # ==== Returns
      #
      # String:: host name
      #
      def hostname
        @hostname ||=
          if user_configuration.has_key?('solr')
            user_configuration['solr']['hostname']
          end || 'localhost'
      end

      #
      # The port at which to connect to Solr. Default 8983.
      #
      # ==== Returns
      #
      # Integer:: port
      #
      def port
        @port ||=
          if user_configuration.has_key?('solr')
            user_configuration['solr']['port']
          end || 8983
      end

      #
      # The path to the Solr servlet (useful if you are running multicore).
      # Default '/solr/data'.
      #
      # ==== Returns
      #
      # String:: path
      #
      def data_path
        @data_path ||=
          if user_configuration.has_key?('solr')
            "#{user_configuration['solr']['data_path'] || user_configuration['solr']['path'] || '/solr/data'}"
          end
      end

      #
      # The path to the Solr pids
      # Default '/solr/pids'.
      #
      # ==== Returns
      #
      # String:: path
      #
      def pids_path
        @pids_path ||=
          if user_configuration.has_key?('solr')
            "#{user_configuration['solr']['pids_path'] || '/solr/pids'}"
          end
      end

      #
      # The path to the Solr home directory
      # Default nil (runs the solr with sunspot default settings).
      #
      # If you have a custom solr conf directory,
      # change this to the directory above your solr conf files
      #
      # e.g. conf files in /solr/conf
      #   solr_home: /solr
      #
      # ==== Returns
      #
      # String:: path
      #
      def solr_home
        @solr_home ||=
          if user_configuration.has_key?('solr')
            if user_configuration['solr']['solr_home'].present?
              user_configuration['solr']['solr_home']
            elsif %w(solrconfig schema).all? { |file| File.exist?(File.join(::Rails.root, 'solr', 'conf', "#{file}.xml")) }
              File.join(::Rails.root, 'solr')
            else
              nil
            else
          end
      end

      private

      #
      # Memoized hash of configuration options for the current Rails environment
      # as specified in config/sunspot.yml
      #
      # ==== Returns
      #
      # Hash:: configuration options for current environment
      #
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
