module Sunspot
  module Query
    #
    # Encapsulates information common to all queries - in particular, keywords
    # and types.
    #
    class BaseQuery #:nodoc:
      include RSolr::Char

      attr_reader :types
      attr_writer :keywords
      attr_writer :phrase_fields

      def initialize(types, setup)
        @types, @setup = types, setup
      end

      # 
      # Generate params for the base query. If keywords are specified, build
      # params for a dismax query, request all stored fields plus the score,
      # and put the types in a filter query. If keywords are not specified,
      # put the types query in the q parameter.
      #
      def to_params
        { :q => types_phrase }
      end

      private

      # 
      # Boolean phrase that restricts results to objects of the type(s) under
      # query. If this is an open query (no types specified) then it sends a
      # no-op phrase because Solr requires that the :q parameter not be empty.
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
          @types.map { |type| escape(type.name)}
      end
    end
  end
end
