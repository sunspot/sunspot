module Sunspot
  module Rails
    class Server < Sunspot::Server
      # ActiveSupport log levels are integers; this array maps them to the
      # appropriate java.util.logging.Level constant
      LOG_LEVELS = %w(FINE INFO WARNING SEVERE SEVERE INFO)

      def start
        bootstrap
        super
      end

      def run
        bootstrap
        super
      end

      #
      # Bootstrap a new solr_home by creating all required
      # directories. 
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def bootstrap
        unless @bootstrapped
          create_solr_directories and create_solr_configuration_files and copy_custom_solr_libraries
          @bootstrapped = true
        end
      end

      # 
      # Directory to store custom libraries for solr
      #
      def lib_path
        File.join( solr_home, 'lib' )
      end

      # 
      # Directory in which to store PID files
      #
      def pid_dir
        File.join(::Rails.root, 'tmp', 'pids')
      end

      # 
      # Name of the PID file
      #
      def pid_file
        "sunspot-solr-#{::Rails.env}.pid"
      end

      # 
      # Directory to store lucene index data files
      #
      # ==== Returns
      #
      # String:: data_path
      #
      def solr_data_dir
        File.join(solr_home, 'data', ::Rails.env)
      end

      # 
      # Directory to use for Solr home.
      #
      def solr_home
        File.join(::Rails.root, 'solr')
      end

      # 
      # Port on which to run Solr
      #
      def port
        configuration.port
      end

      #
      # Severity level for logging. This is based on the severity level for the
      # Rails logger.
      #
      def log_level
        LOG_LEVELS[::Rails.logger.level]
      end

      # 
      # Log file for Solr. File is in the rails log/ directory.
      #
      def log_file
        File.join(::Rails.root, 'log', "sunspot-solr-#{::Rails.env}.log")
      end

      private

      #
      # access to the Sunspot::Rails::Configuration, defined in
      # sunspot.yml. Use Sunspot::Rails.configuration if you want
      # to access the configuration directly.
      #
      # ==== returns
      #
      # Sunspot::Rails::Configuration:: configuration
      #
      def configuration
        Sunspot::Rails.configuration
      end

      # 
      # Directory to store solr config files
      #
      # ==== Returns
      #
      # String:: config_path
      #
      def config_path
        File.join(solr_home, 'conf')
      end

      #
      # Copy default solr configuration files from sunspot
      # gem to the new solr_home/config directory
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def create_solr_configuration_files
        Dir.glob( File.join( Sunspot::Configuration.solr_default_configuration_location, '*') ).each do |config_file|
          unless File.exists?(File.join(config_path, File.basename(config_file)))
            STDOUT.puts("Copying config file #{File.basename(config_file)} into #{config_path}")
            FileUtils.cp_r( config_file, config_path )
          end
        end
      end

      # 
      # Copy custom libraries used by Sunspot's Solr installation into the local
      # Rails Solr installation
      #
      def copy_custom_solr_libraries
        Dir.glob(File.join(Sunspot::Configuration.solr_default_configuration_location, '..', 'lib', '*.jar')).each do |jar|
          unless File.exists?(File.join(lib_path, File.basename(jar)))
            STDOUT.puts("Copying custom library #{File.basename(jar)} into #{lib_path}")
            FileUtils.cp_r(jar, lib_path)
          end
        end
      end

      # 
      # Create new solr_home, config, log and pid directories
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def create_solr_directories
        [ solr_home, config_path, solr_data_dir, pid_dir, lib_path ].each do |path|
          FileUtils.mkdir_p( path )
        end
      end
    end
  end
end
