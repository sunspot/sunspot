ENV['RUBYOPT'] = '-W1'

task :environment do
  require File.dirname(__FILE__) + '/lib/sunspot'
end

Dir['tasks/**/*.rake'].each { |t| load t }

task :default => 'spec:api'
