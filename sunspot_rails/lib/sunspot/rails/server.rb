require 'escape'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    # The Sunspot::Rails::Server class is a simple wrapper around
    # the start/stop scripts for solr.
    class Server
      
      class << self
        delegate :log_file, :log_level, :port, :solr_home, :to => :configuration
        
        # Name of the sunspot executable (shell script)
        SUNSPOT_EXECUTABLE = (RUBY_PLATFORM =~ /w(in)?32$/ ? 'sunspot-solr.bat' : 'sunspot-solr')
      
        #
        # Start the sunspot-solr server. Bootstrap solr_home first,
        # if neccessary.
        #
        # ==== Returns
        #
        # Boolean:: success
        #
        def start
          bootstrap if bootstrap_neccessary?
          execute( start_command )
        end
        
        # 
        # Run the sunspot-solr server in the foreground. Boostrap
        # solr_home first, if neccessary.
        #
        # ==== Returns
        #
        # Boolean:: success
        #
        def run
          bootstrap if bootstrap_neccessary?
          execute( run_command )
        end
        
        # 
        # Stop the sunspot-solr server.
        #
        # ==== Returns
        #
        # Boolean:: success
        #
        def stop
          execute( stop_command )
        end
        
        # 
        # Directory to store solr config files
        #
        # ==== Returns
        #
        # String:: config_path
        #
        def config_path
          File.join( solr_home, 'conf' )
        end
        
        # 
        # Directory to store lucene index data files
        #
        # ==== Returns
        #
        # String:: data_path
        #
        def data_path
          File.join( solr_home, 'data', ::Rails.env )
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
        
        
        protected
        
        # 
        # Generate the start command for the sunspot-solr executable
        #
        # ==== Returns
        #
        # Array:: sunspot_start_command
        #
        def start_command
          [ SUNSPOT_EXECUTABLE, 'start', '-p', port.to_s, '-d', data_path, '-s', solr_home, '-l', log_level, '--log-file', log_file ]
        end

        #
        # Generate the stop command for the sunspot-solr executable
        #
        # ==== Returns
        #
        # Array:: sunspot_stop_command
        #
        def stop_command
          [ SUNSPOT_EXECUTABLE, 'stop' ]
        end

        # 
        # Generate the run command for the sunspot-solr executable
        #
        # ==== Returns
        # 
        # Array:: run_command
        #
        def run_command
          [ SUNSPOT_EXECUTABLE, 'run', '-p', port.to_s, '-d', data_path, '-s', solr_home, '-l', log_level, '-lf', log_file ]
        end
        
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
        
        private 
        
        #
        # Change directory to the pid file path and execute a
        # command on a subshell.
        # 
        # ==== Returns
        #
        # Boolean:: success
        #
        def execute( command )
          success = false
          FileUtils.cd( pid_path ) do
            success = Kernel.system(Escape.shell_command( command ))
          end
          success
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
        
        #
        # Copy custom solr libraries (like localsolr) to the
        # lib directory
        #
        # ==== Returns
        # 
        # Boolean:: success
        #
        def copy_custom_solr_libraries
          Dir.glob( File.join( Sunspot::Configuration.solr_default_configuration_location, '..', 'lib', '*.jar') ).each do |jar_file|
            FileUtils.cp( jar_file, lib_path )
          end
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
      end
    end
  end
end