require 'escape'

module Sunspot #:nodoc:
  # The Sunspot::Rails::Server class is a simple wrapper around
  # the start/stop scripts for solr.
  class Server
    # Name of the sunspot executable (shell script)
    SOLR_START_JAR = File.expand_path(
      File.join(File.dirname(__FILE__), '..', '..', 'solr', 'solr', 'start.jar')
    )

    attr_accessor :min_memory, :max_memory, :port, :solr_data_dir, :solr_home, :log_file
    attr_writer :pid_dir, :log_level

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
      FileUtils.mkdir_p(pid_dir)
      File.open(pid_file, 'w') do |file|
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
      command << "-Djava.util.logging.config.file=#{logging_config_path}" if logging_config_path
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

    def pid_file=(pid_file)
      @pid_file = pid_file
      @pid_dir = File.dirname(pid_file)
    end

    private

    def logging_config_path
      return @logging_config_path if defined?(@logging_config_path)
      @logging_config_path =
        if log_file
          logging_config = Tempfile.new('logging.properties')
          logging_config.puts(".level = #{log_level.to_s.upcase}")
          logging_config.puts("handlers = java.util.logging.FileHandler")
          logging_config.puts("java.util.logging.FileHandler.pattern = #{log_file}")
          logging_config.puts("java.util.logging.FileHandler.formatter = java.util.logging.SimpleFormatter")
          logging_config.flush
          logging_config.close
          logging_config.path
        end
    end

    def log_level
      if @log_level then @log_level.to_s.upcase
      else 'WARN'
      end
    end

    def pid_file
      @pid_file || File.join(pid_dir, 'sunspot-solr.pid')
    end

    def pid_dir
      @pid_dir || FileUtils.pwd
    end
  end
end
