module Sunspot
  class Query
    class BaseQuery
      include RSolr::Char

      attr_accessor :keywords

      def initialize(setup)
        @setup = setup
      end

      def to_params
        params = {}
        if @keywords
          params[:q] = @keywords
          params[:fl] = '* score'
          params[:fq] = types_phrase
          params[:qf] = @setup.text_fields.map do |text_field|
            text_field.indexed_name
          end.join(' ')
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
        if escaped_types.length == 1 then "type:#{escaped_types.first}"
        else "type:(#{escaped_types * ' OR '})"
        end
      end

      #
      # Wraps each type in quotes to escape names of the form Namespace::Class
      #
      def escaped_types
        @escaped_types ||=
          @setup.type_names.map { |name| escape(name)}
      end
    end
  end
end
