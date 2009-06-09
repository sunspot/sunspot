module Mock
  class Connection
    attr_reader :adds

    def initialize
      @adds, @deletes, @deletes_by_query = Array.new(3) { [] }
    end

    def add(documents)
      @adds << Array(documents)
    end

    def delete_by_id(*ids)
      @deletes << ids
    end

    def delete_by_query(query)
      @deletes_by_query << query
    end

    def select(params)
      @last_search = params
    end

    def has_add_with?(*documents)
      @adds.any? do |add|
        documents.all? do |document|
          add.any? do |added|
            if document.is_a?(Hash)
              document.all? do |field, value|
                added.fields_by_name(field).map do |field|
                  field.value
                end == Array(value)
              end
            else
              !added.fields_by_name(document).empty?
            end
          end
        end
      end
    end

    def has_delete?(*ids)
      @deletes.any? do |delete|
        delete & ids == ids
      end
    end

    def has_delete_by_query?(query)
      @deletes_by_query.include?(query)
    end

    def has_last_search_with?(params)
      return unless @last_search
      if params.respond_to?(:all?)
        params.all? do |key, value|
          @last_search.has_key?(key) && @last_search[key] == value
        end
      else
        @last_search.has_key?(params)
      end
    end
  end
end
