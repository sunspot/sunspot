module Sunspot
  module Query
    #
    # Encapsulates information common to all queries - in particular, keywords
    # and types.
    #
    class BaseQuery #:nodoc:
      include RSolr::Char

      attr_writer :keywords

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

      # 
      # Set keyword options
      #
      def keyword_options=(options)
        if options
          @text_field_names = options.delete(:fields)
        end
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

      # 
      # Returns the names of text fields that should be queried in a keyword
      # search. If specific fields are requested, use those; otherwise use the
      # union of all fields configured for the types under search.
      #
      def text_field_names
        text_fields =
          if @text_field_names
            Array(@text_field_names).map do |field_name|
              @setup.text_field(field_name.to_sym)
            end
          else
            @setup.text_fields
          end
        text_fields.map do |text_field|
          text_field.indexed_name
        end
      end
    end
  end
end
