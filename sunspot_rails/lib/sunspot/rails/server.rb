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
      # Directory to store lucene index data files
      #
      # ==== Returns
      #
      # String:: data_path
      #
      def solr_data_dir
        configuration.data_path
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
      def solr_jar
        configuration.solr_jar || super
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
    end
  end
end
