require 'escape'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    # The Sunspot::Rails::Server class is a simple wrapper around
    # the start/stop scripts for solr.
    class Server
      
      class << self
        delegate :port, :to => :configuration
        
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
        
        
        def solr_home
          @@solr_home   ||= File.join( ::Rails.root, 'solr' )
        end
        
        def config_path
          @@config_path ||= File.join( solr_home, 'conf' )
        end
        
        def data_path
          @@data_path   ||= File.join( solr_home, 'data', ::Rails.env )
        end
        
        def pid_path
          @@pid_path    ||= File.join( solr_home, 'pids', ::Rails.env )
        end
        
        
        def bootstrap
          raise(RuntimeError, 'not implemented')
        end
        
        def bootstrap_neccessary?
          false
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
          [ SUNSPOT_EXECUTABLE, 'start', '--', '-p', port.to_s, '-d', data_path, '-s', solr_home ]
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
          [ SUNSPOT_EXECUTABLE, 'run' ]
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
end