require 'sunspot/rails'

if Rails::VERSION::MAJOR == 3
  require 'sunspot/rails/railtie'
else
  require 'sunspot/rails/init'
end
