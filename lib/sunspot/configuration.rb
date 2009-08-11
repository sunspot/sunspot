module Sunspot
  # The Sunspot::Configuration module provides a factory method for Sunspot
  # configuration objects. Available properties are:
  #
  # Sunspot.config.http_client::
  #   The client to use for HTTP communication with Solr. Available options are
  #   :net_http, which is the default and uses Ruby's built-in pure-Ruby HTTP
  #   library; and :curb, which uses Ruby's libcurl bindings and requires
  #   installation of the 'curb' gem.
  # Sunspot.config.solr.url::
  #   The URL at which to connect to Solr
  #   (default: 'http://localhost:8983/solr')
  # Sunspot.config.pagination.default_per_page::
  #   Solr always paginates its results. This sets Sunspot's default result
  #   count per page if it is not explicitly specified in the query.
  #
  module Configuration
    class <<self
      # Factory method to build configuration instances.
      #
      # ==== Returns
      #
      # LightConfig::Configuration:: new configuration instance with defaults
      #
      def build #:nodoc:
        LightConfig.build do
          http_client :net_http
          solr do
            url 'http://127.0.0.1:8983/solr'
          end
          pagination do
            default_per_page 30
          end
        end
      end
    end
  end
end
