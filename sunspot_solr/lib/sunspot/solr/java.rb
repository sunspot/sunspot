require 'rbconfig'

module Sunspot
  module Solr
    module Java
      NULL_DEVICE = RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL' : '/dev/null'

      def self.installed?
        system "java -version >#{NULL_DEVICE} 2>&1"
      end
    end
  end
end
