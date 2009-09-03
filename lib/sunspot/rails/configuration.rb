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
    #       log_level: OFF
    #   production:
    #     solr:
    #       hostname: localhost
    #       port: 8983
    #       path: /solr/myindex
    #       log_level: WARNING
    #       solr_home: /some/path
    #     auto_commit_after_request: true
    #
    # Sunspot::Rails uses the configuration to set up the Solr connection, as
    # well as for starting Solr with the appropriate port using the
    # <code>rake sunspot:solr:start</code> task.
    #
    class Configuration
      attr_writer :user_configuration
      #
      # The host name at which to connect to Solr. Default 'localhost'.
      #
      # ==== Returns
      #
      # String:: host name
      #
      def hostname
        @hostname ||= (user_configuration_from_key('solr', 'hostname') || 'localhost')
      end

      #
      # The port at which to connect to Solr. Default 8983.
      #
      # ==== Returns
      #
      # Integer:: port
      #
      def port
        @port ||= (user_configuration_from_key('solr', 'port') || 8983).to_i
      end

      #
      # The url path to the Solr servlet (useful if you are running multicore).
      # Default '/solr'.
      #
      # ==== Returns
      #
      # String:: path
      #
      def path
        @path ||= (user_configuration_from_key('solr', 'path') || '/solr')
      end

      # 
      # The default log_level that should be passed to solr. You can
      # change the individual log_levels in the solr admin interface.
      # Default 'INFO'.
      #
      # ==== Returns
      #
      # String:: log_level
      #
      def log_level
        @log_level ||= (user_configuration_from_key('solr', 'log_level') || 'INFO')
      end
      
      # 
      # The solr home directory. Sunspot::Rails expects this directory
      # to contain a config, data and pids directory. See 
      # Sunspot::Rails::Server.bootstrap for more information.
      #
      # ==== Returns
      #
      # String:: solr_home
      #
      def solr_home
        @solr_home ||= (user_configuration_from_key('solr', 'solr_home') || File.join( ::Rails.root, 'solr' ))
      end
      
      #
      # Should the solr index receive a commit after each http-request.
      # Default true
      #
      # ==== Returns
      #
      # Boolean:: bool
      #
      def auto_commit_after_request?
        @auto_commit_after_request ||= 
          user_configuration_from_key('auto_commit_after_request') != false
      end

      #
      # The path to the Solr indexes. (Used by the rake tasks).
      # Default RAILS_ROOT + '/solr/data/' + ENVIRONMENT
      #
      # ==== Returns
      #
      # String:: path
      #
      def data_path
        @data_path ||=
          if user_configuration.has_key?('solr')
            "#{user_configuration['solr']['data_path'] || File.join(::Rails.root, 'solr', 'data', ::Rails.env)}"
          end
      end

      #
      # The path to the Solr pids
      # Default RAILS_ROOT + '/solr/pids/' + ENVIRONMENT
      #
      # ==== Returns
      #
      # String:: path
      #
      def pid_path
        @pids_path ||=
          if user_configuration.has_key?('solr')
            "#{user_configuration['solr']['pid_path'] || File.join(::Rails.root, 'solr', 'pids', ::Rails.env)}"
          end
      end

      #
      # The path to the Solr home directory
      # Default nil (runs the solr with sunspot default settings).
      #
      # If you have a custom solr conf directory,
      # change this to the directory above your solr conf files
      #
      # e.g. conf files in RAILS_ROOT/solr/conf
      #   solr_home: RAILS_ROOT/solr
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
            end
          end
      end

      private
      
      # 
      # return a specific key from the user configuration in config/sunspot.yml
      #
      # ==== Returns
      #
      # Mixed:: requested_key or nil
      #
      def user_configuration_from_key( *keys )
        keys.inject(user_configuration) do |hash, key|
          hash[key] if hash
        end
      end

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
            else
              {}
            end
          end
      end
    end
  end
end
