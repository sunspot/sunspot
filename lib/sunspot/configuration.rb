module Sunspot
  module Configuration
  end

  class <<Configuration
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
