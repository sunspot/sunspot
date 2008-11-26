module Sunspot
  module Configuration
  end
  
  class <<Configuration
    def build
      LightConfig.build do
        solr do
          url 'http://localhost:8983/solr'
        end
      end
    end
  end
end
