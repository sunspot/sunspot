ENV['RUBYOPT'] = '-W1'

task :environment do
  require File.dirname(__FILE__) + '/lib/sunspot'
end

require File.join(File.dirname(__FILE__), 'lib', 'sunspot', 'version')

Dir['tasks/**/*.rake'].each { |t| load t }

task :default => 'spec:api'
