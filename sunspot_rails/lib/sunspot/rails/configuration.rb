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
    #       min_memory: 512M
    #       max_memory: 1G
    #       solr_jar: /some/path/solr15/start.jar
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
    #     master_solr:
    #       hostname: localhost
    #       port: 8982
    #       path: /solr
    #     auto_commit_after_request: true
    #
    # Sunspot::Rails uses the configuration to set up the Solr connection, as
    # well as for starting Solr with the appropriate port using the
    # <code>rake sunspot:solr:start</code> task.
    #
    # If the <code>master_solr</code> configuration is present, Sunspot will use
    # the Solr instance specified here for all write operations, and the Solr
    # configured under <code>solr</code> for all read operations.
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
        unless defined?(@hostname)
          @hostname   = solr_url.host if solr_url
          @hostname ||= user_configuration_from_key('solr', 'hostname')
          @hostname ||= default_hostname
        end
        @hostname
      end
      
      #
      # The port at which to connect to Solr.
      # Defaults to 8981 in test, 8982 in development and 8983 in production.
      #
      # ==== Returns
      #
      # Integer:: port
      #
      def port
        unless defined?(@port)
          @port   = solr_url.port if solr_url
          @port ||= user_configuration_from_key('solr', 'port')
          @port ||= default_port
          @port   = @port.to_i
        end
        @port
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
        unless defined?(@path)
          @path   = solr_url.path if solr_url
          @path ||= user_configuration_from_key('solr', 'path')
          @path ||= default_path
        end
        @path
      end

      #
      # The host name at which to connect to the master Solr instance. Defaults
      # to the 'hostname' configuration option.
      #
      # ==== Returns
      #
      # String:: host name
      #
      def master_hostname
        @master_hostname ||= (user_configuration_from_key('master_solr', 'hostname') || hostname)
      end

      #
      # The port at which to connect to the master Solr instance. Defaults to
      # the 'port' configuration option.
      #
      # ==== Returns
      #
      # Integer:: port
      #
      def master_port
        @master_port ||= (user_configuration_from_key('master_solr', 'port') || port).to_i
      end

      #
      # The path to the master Solr servlet (useful if you are running multicore).
      # Defaults to the value of the 'path' configuration option.
      #
      # ==== Returns
      #
      # String:: path
      #
      def master_path
        @master_path ||= (user_configuration_from_key('master_solr', 'path') || path)
      end

      #
      # True if there is a master Solr instance configured, otherwise false.
      #
      # ==== Returns
      #
      # Boolean:: bool
      #
      def has_master?
        @has_master = !!user_configuration_from_key('master_solr')
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
      # Should the solr index receive a commit after each http-request.
      # Default true
      #
      # ==== Returns
      # 
      # Boolean: auto_commit_after_request?
      #
      def auto_commit_after_request?
        @auto_commit_after_request ||= 
          user_configuration_from_key('auto_commit_after_request') != false
      end
      
      #
      # As for #auto_commit_after_request? but only for deletes
      # Default false
      #
      # ==== Returns
      # 
      # Boolean: auto_commit_after_delete_request?
      #
      def auto_commit_after_delete_request?
        @auto_commit_after_delete_request ||= 
          (user_configuration_from_key('auto_commit_after_delete_request') || false)
      end
      
      
      #
      # The log directory for solr logfiles
      #
      # ==== Returns
      # 
      # String:: log_dir
      #
      def log_file
        @log_file ||= (user_configuration_from_key('solr', 'log_file') || default_log_file_location )
      end

      def data_path
        @data_path ||= user_configuration_from_key('solr', 'data_path') || File.join(::Rails.root, 'solr', 'data', ::Rails.env)
      end
      
      def pid_path
        @pids_path ||= user_configuration_from_key('solr', 'pid_path') || File.join(::Rails.root, 'solr', 'pids', ::Rails.env)
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
        @solr_home ||=
          if user_configuration_from_key('solr', 'solr_home')
            user_configuration_from_key('solr', 'solr_home')
          else
            File.join(::Rails.root, 'solr')
          end
      end

      # 
      # Solr start jar
      #
      def solr_jar
        @solr_jar ||= user_configuration_from_key('solr', 'solr_jar')
      end

      # 
      # Minimum java heap size for Solr instance
      #
      def min_memory
        @min_memory ||= user_configuration_from_key('solr', 'min_memory')
      end

      # 
      # Maximum java heap size for Solr instance
      #
      def max_memory
        @max_memory ||= user_configuration_from_key('solr', 'max_memory')
      end
      
      private
      
      #
      # Logging in rails_root/log as solr_<environment>.log as a 
      # default.
      #
      # ===== Returns
      #
      # String:: default_log_file_location
      #
      def default_log_file_location
        File.join(::Rails.root, 'log', "solr_" + ::Rails.env + ".log")
      end
      
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
    
    protected
    
      #
      # When a specific hostname, port and path aren't provided in the
      # sunspot.yml file, look for a key named 'url', then check the
      # environment, then fall back to a sensible localhost default.
      #
      
      def solr_url
        if ENV['SOLR_URL'] || ENV['WEBSOLR_URL']
          URI.parse(ENV['SOLR_URL'] || ENV['WEBSOLR_URL'])
        end
      end
      
      def default_hostname
        'localhost'
      end
      
      def default_port
        { 'test'        => 8981,
          'development' => 8982,
          'production'  => 8983
        }[::Rails.env]  || 8983
      end
      
      def default_path
        '/solr'
      end
      
    end
  end
end
