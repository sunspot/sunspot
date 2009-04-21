module Sunspot
  module Configuration
    class <<self
      def build
        LightConfig.build do
          solr do
            url 'http://localhost:8983/solr'
          end
          pagination do
            default_per_page 30
          end
        end
      end
    end
  end
end
