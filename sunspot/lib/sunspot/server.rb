require 'escape'
require 'set'

module Sunspot #:nodoc:
  # The Sunspot::Rails::Server class is a simple wrapper around
  # the start/stop scripts for solr.
  class Server
    # Raised if #stop is called but the server is not running
    NotRunningError = Class.new(RuntimeError)

    # Name of the sunspot executable (shell script)
    SOLR_START_JAR = File.expand_path(
      File.join(File.dirname(__FILE__), '..', '..', 'solr', 'start.jar')
    )

    LOG_LEVELS = Set['SEVERE', 'WARNING', 'INFO', 'CONFIG', 'FINE', 'FINER', 'FINEST']

    attr_accessor :min_memory, :max_memory, :port, :solr_data_dir, :solr_home, :log_file
    attr_writer :pid_dir, :log_level, :solr_data_dir, :solr_home

    #
    # Start the sunspot-solr server. Bootstrap solr_home first,
    # if neccessary.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def start
      if File.exist?(pid_file)
        existing_pid = IO.read(pid_file).to_i
        begin
          Process.kill(0, existing_pid)
          abort("Server is already running with PID #{existing_pid}")
        rescue Errno::ESRCH
          STDERR.puts("Removing stale PID file at #{pid_file}")
          FileUtils.rm(pid_file)
        end
      end
      fork do
        pid = fork do
          Process.setsid
          STDIN.reopen('/dev/null')
          STDOUT.reopen('/dev/null', 'a')
          STDERR.reopen(STDOUT)
          run
        end
        FileUtils.mkdir_p(pid_dir)
        File.open(pid_file, 'w') do |file|
          file << pid
        end
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
      command << '-jar' << File.basename(SOLR_START_JAR)
      FileUtils.cd(File.dirname(SOLR_START_JAR)) do
        exec(Escape.shell_command(command))
      end
    end

    # 
    # Stop the sunspot-solr server.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def stop
      if File.exist?(pid_file)
        pid = IO.read(pid_file).to_i
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          raise NotRunningError, "Process with PID #{pid} is no longer running"
        ensure
          FileUtils.rm(pid_file)
        end
      else
        raise NotRunningError, "No PID file at #{pid_file}"
      end
    end

    def log_level=(level)
      unless LOG_LEVELS.include?(level.to_s.upcase)
        raise(ArgumentError, "#{level} is not a valid log level: Use one of #{LOG_LEVELS.to_a.join(',')}")
      end
      @log_level = level.to_s.upcase
    end

    def log_level
      @log_level || 'WARNING'
    end

    def pid_file=(pid_file)
      @pid_file = pid_file
      @pid_dir = File.dirname(pid_file)
    end

    def pid_file
      File.expand_path(@pid_file || File.join(pid_dir, 'sunspot-solr.pid'))
    end

    def pid_dir
      File.expand_path(@pid_dir || FileUtils.pwd)
    end

    def solr_data_dir
      File.expand_path(@solr_data_dir || Dir.tmpdir)
    end

    def solr_home
      File.expand_path(@solr_home || File.join(File.dirname(SOLR_START_JAR), 'solr'))
    end

    private

    def logging_config_path
      return @logging_config_path if defined?(@logging_config_path)
      @logging_config_path =
        if log_file
          logging_config = Tempfile.new('logging.properties')
          logging_config.puts("handlers = java.util.logging.FileHandler")
          logging_config.puts("java.util.logging.FileHandler.level = #{log_level.to_s.upcase}")
          logging_config.puts("java.util.logging.FileHandler.pattern = #{log_file}")
          logging_config.puts("java.util.logging.FileHandler.formatter = java.util.logging.SimpleFormatter")
          logging_config.flush
          logging_config.close
          logging_config.path
        end
    end
  end
end
