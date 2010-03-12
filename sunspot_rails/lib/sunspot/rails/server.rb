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
          install_solr_home
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
      # Solr start jar
      #
      def solr_jar
          configuration.solr_jar || super
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

      # 
      # Minimum Java heap size for Solr
      #
      def min_memory
        configuration.min_memory
      end

      # 
      # Maximum Java heap size for Solr
      #
      def max_memory
        configuration.max_memory
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
      def install_solr_home
        unless File.exists?(solr_home)
          Sunspot::Installer.execute(
            solr_home,
            :force => true,
            :verbose => true
          )
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
        [solr_data_dir, pid_dir].each do |path|
          FileUtils.mkdir_p( path )
        end
      end
    end
  end
end
