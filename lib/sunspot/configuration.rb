class <<Sunspot
  def config
    @config ||= LightConfig.build do
      solr do
        url 'http://localhost:8983/solr'
      end
    end
  end
end
