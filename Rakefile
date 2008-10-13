require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

task :default => :spec

Dir['tasks/**/*.rake'].each { |rake| load rake }
