require 'escape'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    class Util
      class << self
        def sunspot_options
          @sunspot_options ||= {}
        end
        
        def index_relevant_attribute_changed?( object )
          class_key = object.class.to_s.underscore.to_sym
          ignore_attributes = (sunspot_options[class_key][:ignore_attribute_changes_of] || [])
          !(object.changes.symbolize_keys.keys - ignore_attributes).blank?
        end
        
      end
    end
  end
end
