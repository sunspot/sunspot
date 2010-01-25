module Sunspot
  module Rails
    class Server < Sunspot::Server
      #
      # Bootstrap a new solr_home by creating all required
      # directories. 
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def bootstrap
        create_solr_directories and create_solr_configuration_files and copy_custom_solr_libraries
      end

      # 
      # Check for bootstrap necessity
      #
      # ==== Returns
      #
      # Boolean:: neccessary
      #
      def bootstrap_neccessary?
        !File.directory?( solr_home ) or !File.exists?( File.join( config_path, 'solrconfig.xml' ) )
      end

      # 
      # Directory to store custom libraries for solr
      #
      # ==== Returns
      #
      # String:: lib_path
      #
      def lib_path
        File.join( solr_home, 'lib' )
      end

      # 
      # Directory to store pid files
      #
      # ==== Returns
      #
      # String:: pid_path
      #
      def pid_path
        File.join( solr_home, 'pids', ::Rails.env )
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
      # Directory to store lucene index data files
      #
      # ==== Returns
      #
      # String:: data_path
      #
      def data_path
        File.join(solr_home, 'data', ::Rails.env)
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
          FileUtils.cp( config_file, config_path )
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
        [ solr_home, config_path, data_path, pid_path, lib_path ].each do |path|
          FileUtils.mkdir_p( path )
        end
      end
    end
  end
end
