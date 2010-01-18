module Solr
  class Document
    def field_by_name(field_name)
      @fields.find { |field| field.name.to_s == field_name.to_s }
    end

    def fields_by_name(field_name)
      @fields.select { |field| field.name.to_s == field_name.to_s }
    end
  end
end
