require 'escape'

module Sunspot #:nodoc:
  # The Sunspot::Rails::Server class is a simple wrapper around
  # the start/stop scripts for solr.
  class Server
    # Name of the sunspot executable (shell script)
    SOLR_START_JAR = File.expand_path(
      File.join(File.dirname(__FILE__), '..', '..', 'solr', 'solr', 'start.jar')
    )

    attr_accessor :min_memory, :max_memory, :port, :solr_data_dir, :solr_home

    #
    # Start the sunspot-solr server. Bootstrap solr_home first,
    # if neccessary.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def start
      pid = fork { run }
      File.open('./sunspot-solr.pid', 'w') do |file|
        file << pid
      end
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
      command = ['java']
      command << "-Xms#{min_memory}" if min_memory
      command << "-Xmx#{max_memory}" if max_memory
      command << "-Djetty.port=#{port}" if port
      command << "-Dsolr.data.dir=#{solr_data_dir}" if solr_data_dir
      command << "-Dsolr.solr.home=#{solr_home}" if solr_home
      command << '-jar' << SOLR_START_JAR
      exec(Escape.shell_command(command))
    end

    # 
    # Stop the sunspot-solr server.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def stop
      execute(stop_command)
    end
  end
end
