module Sunspot
  # The Sunspot::Configuration module provides a factory method for Sunspot
  # configuration objects. Available properties are:
  #
  # Sunspot.config.http_client::
  #   The client to use for HTTP communication with Solr. Available options are
  #   :net_http, which is the default and uses Ruby's built-in pure-Ruby HTTP
  #   library; and :curb, which uses Ruby's libcurl bindings and requires
  #   installation of the 'curb' gem.
  # Sunspot.config.xml_builder::
  #   The library use to build XML messages sent to Solr. As of this writing the
  #   options are :builder and :libxml - the latter is faster but less portable,
  #   as it is native code. Check the documentation for RSolr::Message::Adapter
  #   for more information.
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
          solr do
            url 'http://127.0.0.1:8983/solr'
          end
          master_solr do
            url nil
          end
          pagination do
            default_per_page 30
          end
        end
      end
      
      # Location for the default solr configuration files,
      # required for bootstrapping a new solr installation
      #
      # ==== Returns
      #
      # String:: Directory with default solr config files
      #
      def solr_default_configuration_location
        File.join( File.dirname(__FILE__), '../../solr/solr/conf' )
      end
    end
  end
end
