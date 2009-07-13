module Sunspot
  class Query
    class BaseQuery
      include RSolr::Char

      attr_accessor :keywords

      def initialize(types)
        @types = types
      end

      def to_params
        params = {}
        if @keywords
          params[:q] = @keywords
          params[:fl] = '* score'
          params[:fq] = types_phrase
          params[:qf] = text_field_names.join(' ')
          params[:defType] = 'dismax'
        else
          params[:q] = types_phrase
        end
        params
      end

      private

      # 
      # Boolean phrase that restricts results to objects of the type(s) under
      # query. If this is an open query (no types specified) then it sends a
      # no-op phrase because Solr requires that the :q parameter not be empty.
      #
      # TODO don't send a noop if we have a keyword phrase
      # TODO this should be sent as a filter query when possible, especially
      #      if there is a single type, so that Solr can cache it
      #
      # ==== Returns
      #
      # String:: Boolean phrase for type restriction
      #
      def types_phrase
        if @types.nil? || @types.empty? then "type:[* TO *]"
        elsif @types.length == 1 then "type:#{escaped_types.first}"
        else "type:(#{escaped_types * ' OR '})"
        end
      end

      #
      # Wraps each type in quotes to escape names of the form Namespace::Class
      #
      def escaped_types
        @types.map { |t| escape(t.name)}
      end

      #XXX do this in field composite class
      def text_field_names
        @types.inject([]) do |fields, type|
          fields.concat(
            Setup.for(type).text_fields.map { |field| field.indexed_name.to_s }
          )
        end
      end
    end
  end
end
