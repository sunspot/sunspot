require "rbconfig"

module Sunspot
  module Solr
    module Java
      class << self
        def ensure_install!
          if installed?
            true
          else
            raise Sunspot::Solr::Server::JavaMissing, "You need a Java Runtime Environment to run the Solr server"
          end
        end

        def installed?
          system("java", "-version", [:out, :err] => null_device)
          $?.exitstatus.zero?
        end

        def null_device
          RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ ? "NUL" : "/dev/null"
        end
      end
    end
  end
end
