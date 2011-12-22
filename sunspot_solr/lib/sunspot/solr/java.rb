module Sunspot
  module Solr
    module Java
      def self.installed?
        `java -version`
        $?.success?
      end
    end
  end
end
