require 'set'
require 'tempfile'
require 'sunspot/solr/java'
require 'sunspot/solr/installer'

module Sunspot
  module Solr
    class Server #:nodoc:
      # Raised if #stop is called but the server is not running
      ServerError = Class.new(RuntimeError)
      AlreadyRunningError = Class.new(ServerError)
      NotRunningError = Class.new(ServerError)
      JavaMissing = Class.new(ServerError)

      # Name of the sunspot executable (shell script)
      SOLR_START_JAR = File.expand_path(
        File.join(File.dirname(__FILE__), '..', '..', '..', 'solr', 'start.jar')
      )

      LOG_LEVELS = Set['SEVERE', 'WARNING', 'INFO', 'CONFIG', 'FINE', 'FINER', 'FINEST']

      attr_accessor :min_memory, :max_memory, :bind_address, :port, :log_file

      attr_writer :pid_dir, :pid_file, :solr_data_dir, :solr_home, :solr_jar

      def initialize(*args)
        ensure_java_installed
        super(*args)
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
          create_solr_directories
          @bootstrapped = true
        end
      end

      #
      # Start the sunspot-solr server. Bootstrap solr_home first,
      # if neccessary.
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def start
        bootstrap

        if File.exist?(pid_path)
          existing_pid = IO.read(pid_path).to_i
          begin
            Process.kill(0, existing_pid)
            raise(AlreadyRunningError, "Server is already running with PID #{existing_pid}")
          rescue Errno::ESRCH
            STDERR.puts("Removing stale PID file at #{pid_path}")
            FileUtils.rm(pid_path)
          end
        end
        fork do
          pid = fork do
            Process.setsid
            STDIN.reopen('/dev/null')
            STDOUT.reopen('/dev/null')
            STDERR.reopen(STDOUT)
            run
          end
          FileUtils.mkdir_p(pid_dir)
          File.open(pid_path, 'w') do |file|
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
        bootstrap

        command = ['java']
        command << "-Xms#{min_memory}" if min_memory
        command << "-Xmx#{max_memory}" if max_memory
        command << "-Djetty.port=#{port}" if port
        command << "-Djetty.host=#{bind_address}" if bind_address
        command << "-Dsolr.data.dir=#{solr_data_dir}" if solr_data_dir
        command << "-Dsolr.solr.home=#{solr_home}" if solr_home
        command << "-Djava.util.logging.config.file=#{logging_config_path}" if logging_config_path
        command << '-jar' << File.basename(solr_jar)
        FileUtils.cd(File.dirname(solr_jar)) do
          exec(*command)
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
        if File.exist?(pid_path)
          pid = IO.read(pid_path).to_i
          begin
            Process.kill('TERM', pid)
          rescue Errno::ESRCH
            raise NotRunningError, "Process with PID #{pid} is no longer running"
          ensure
            FileUtils.rm(pid_path)
          end
        else
          raise NotRunningError, "No PID file at #{pid_path}"
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

      def pid_path
        File.join(pid_dir, pid_file)
      end

      def pid_file
        @pid_file || 'sunspot-solr.pid'
      end

      def pid_dir
        File.expand_path(@pid_dir || FileUtils.pwd)
      end

      def solr_data_dir
        File.expand_path(@solr_data_dir || Dir.tmpdir)
      end

      def solr_home
        File.expand_path(@solr_home || File.join(File.dirname(solr_jar), 'solr'))
      end

      def solr_jar
        @solr_jar || SOLR_START_JAR
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
          Sunspot::Solr::Installer.execute(
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
          FileUtils.mkdir_p(path) unless File.exists?(path)
        end
      end

      private

      def ensure_java_installed
        unless defined?(@java_installed)
          @java_installed = Sunspot::Solr::Java.installed?
          unless @java_installed
            raise JavaMissing.new("You need a Java Runtime Environment to run the Solr server")
          end
        end
        @java_installed
      end

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
end
