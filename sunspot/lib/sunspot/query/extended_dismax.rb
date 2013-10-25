module Sunspot
  module Query
    class ExtendedDismax < Dismax
      def to_params
        params = super
        params[:defType] = 'edismax'
        params
      end

      def to_subquery
        params = self.to_params
        params.delete :defType
        params.delete :fl
        keywords = params.delete(:q)
        options = params.map { |key, value| escape_param(key, value) }.join(' ')
        "_query_:\"{!edismax #{options}}#{escape_quotes(keywords)}\""
      end
    end

    RegisteredParser.register(:edismax,ExtendedDismax)
  end
end