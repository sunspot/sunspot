module Sunspot
  module Solr
    module Java
      def self.installed?
        java_cmd = RUBY_PLATFORM =~ /i386/ ? 'java -version' : 'java -version &> /dev/null'
        system(java_cmd)
        $?.success?
      end
    end
  end
end
