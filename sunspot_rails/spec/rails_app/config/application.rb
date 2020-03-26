require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

# Load the test engine
require File.expand_path('../../vendor/engines/test_engine/lib/test_engine', __FILE__)

module RailsApp
  class Application < Rails::Application
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
