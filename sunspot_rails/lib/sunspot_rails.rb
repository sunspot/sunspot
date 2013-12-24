# This needs to be loaded before sunspot/search/paginated_collection
# or #to_json gets defined in Object breaking delegation to Array via
# method_missing
if ::Rails.version >= '4.1'
  require 'active_support/core_ext/object/json'
elsif ::Rails.version >= '3'
  require 'active_support/core_ext/object/to_json'
end

require 'sunspot/rails'
require 'sunspot/rails/railtie'
