module Mock
  class ConnectionFactory
    def connect(opts)
      if @instance
        raise('Factory can only create an instance once!')
      else
        @instance = Connection.new(opts)
      end
    end

    def new(url = nil)
      if @instance
        raise('Factory can only create an instance once!')
      else
        @instance = Connection.new(url)
      end
    end

    def instance
      @instance ||= Connection.new
    end
  end

  class Connection
    attr_reader :adds, :commits, :searches, :mlts, :message, :opts, :deletes_by_query
    attr_accessor :response

    def initialize(opts = {})
      @opts = opts
      @message = OpenStruct.new
      @adds, @deletes, @deletes_by_query, @commits, @searches, @mlts = Array.new(6) { [] }
    end

    def add(documents)
      @adds << Array(documents)
    end

    def delete_by_id(ids)
      @deletes << Array(ids)
    end

    def delete_by_query(query)
      @deletes_by_query << query
    end

    def commit
      @commits << Time.now
    end

    def select(request)
      @searches << @last_search = request
      @response || {}
    end

    def mlt(request)
      @mlts << @last_mlt = request
      @response || {}
    end

    def has_add_with?(*documents)
      @adds.any? do |add|
        documents.all? do |document|
          add.any? do |added|
            if document.is_a?(Hash)
              document.all? do |field, value|
                added.fields_by_name(field).map do |field|
                  field.value.to_s
                end == Array(value).map { |v| v.to_s }
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
      with?(@last_search, params) if @last_search
    end

    def has_last_search_including?(key, *values)
      return unless @last_search
      if @last_search.has_key?(key)
        if @last_search[key].is_a?(Array)
          (@last_search[key] & values).length == values.length
        elsif values.length == 1
          @last_search[key] == values.first
        end
      end
    end

    def has_last_mlt_with?(params)
      with?(@last_mlt, params) if @last_mlt
    end

    private

    def with?(request, params)
      if params.respond_to?(:all?)
        params.all? do |key, value|
          if request.has_key?(key)
            request[key] == value
          end
        end
      else
        request.has_key?(params)
      end
    end
  end
end
