module Sunspot
  module Builder
    class AbstractBuilder
      attr_reader :search, :types, :field_names

      def initialize(query_dsl, types, field_names)
        @search, @types, @field_names = query_dsl, types, field_names
      end
    end

    class ParamsBuilder < AbstractBuilder
      attr_reader :params

      def initialize(query_dsl, types, field_names, params = {})
        super(query_dsl, types, field_names)
        @params = params
        params.each_pair do |field_name, value|
          self.send("#{field_name}=", value)
        end
      end
    end

    class StandardBuilder < ParamsBuilder
      def initialize(query_dsl, types, field_names, params = {})
        params = { :keywords => nil, :conditions => {},
                   :order => nil, :page => nil,
                   :per_page => nil }.merge(params)
        field_names.each do |field_name|
          unless params[:conditions].has_key?(field_name.to_sym)
            params[:conditions][field_name.to_sym] = nil
          end
        end
        super(query_dsl, types, field_names, params)
      end

      def keywords=(keywords)
        search.keywords(keywords) if keywords
      end

      def conditions=(conditions)
        conditions.each_pair do |field_name, value|
          unless value.nil?
            unless value.is_a?(Array)
              if field_names.include?(field_name.to_s)
                search.with.send(field_name, value)
              end
            else
              search.with.send(field_name).any_of(value)
            end
          end
        end
      end

      def order=(order_string)
        search.order_by(*order_string.split(' ')) if order_string
      end

      def page=(page)
        search.paginate(:page => page, :per_page => params[:per_page]) if page
      end

      def per_page=(per_page) # ugly
      end

      def keywords
        params[:keywords]
      end

      def conditions
        ::Sunspot::Util::ClosedStruct.new(params[:conditions])
      end

      def order
        params[:order]
      end

      def page
        params[:page]
      end

      def per_page
        params[:per_page]
      end
    end
  end
end
