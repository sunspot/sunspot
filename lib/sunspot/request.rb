module Sunspot
  # 
  # Request object implementing solr-ruby's Request API but passing the given
  # params to Solr without molestation.
  #
  module Request
    class Select < Solr::Request::Base
      def initialize(params)
        @params = params
      end

      def handler
        'select'
      end

      def response_format
        :ruby
      end

      def to_hash
        @params.merge(:wt => 'ruby')
      end

      def content_type
        'application/x-www-form-urlencoded; charset=utf-8'
      end

      def to_s
        query = []
        to_hash.each_pair do |key, values|
          Util.Array(values).each do |value|
            query << "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
          end
        end
        query.join('&')
      end
    end
  end

  module Response
    Select = Solr::Response::Select
  end
end
