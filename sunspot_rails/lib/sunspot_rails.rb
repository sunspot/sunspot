# This needs to be loaded before sunspot/search/paginated_collection
# or #to_json gets defined in Object breaking delegation to Array via
# method_missing
require 'active_support/core_ext/object/to_json'

require 'sunspot/rails'
require 'sunspot/rails/railtie'
