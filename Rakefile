require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

task :default => :test

Dir['tasks/**/*.rake'].each { |rake| load rake }
