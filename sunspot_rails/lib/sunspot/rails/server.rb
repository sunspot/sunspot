module Sunspot
  module Rails
    class Server < Sunspot::Solr::Server

      #
      # Directory in which to store PID files
      #
      def pid_dir
        configuration.pid_dir || File.join(::Rails.root, 'tmp', 'pids')
      end

      #
      # Name of the PID file
      #
      def pid_file
        "sunspot-solr-#{::Rails.env}.pid"
      end

      #
      # Directory to use for Solr home.
      #
      def solr_home
        File.join(configuration.solr_home)
      end

      #
      # Solr start jar
      #
      def solr_executable
        configuration.solr_executable || super
      end

      #
      # Address on which to run Solr
      #
      def bind_address
        configuration.bind_address
      end

      #
      # Port on which to run Solr
      #
      def port
        configuration.port
      end

      def log_level
        configuration.log_level
      end

      #
      # Log file for Solr. File is in the rails log/ directory.
      #
      def log_file
        File.join(::Rails.root, 'log', "sunspot-solr-#{::Rails.env}.log")
      end

      #
      # Java heap size for Solr
      #
      def memory
        configuration.memory
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
    end
  end
end
