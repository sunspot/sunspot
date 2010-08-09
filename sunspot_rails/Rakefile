require 'rake'
require 'rake/rdoctask'

if File.exist?(sunspot_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'sunspot', 'lib')))
  STDERR.puts("Using sunspot lib at #{sunspot_lib}")
  $: << sunspot_lib
end

task :environment do
  if ENV['SUNSPOT_LIB']
    $: << ENV['SUNSPOT_LIB']
  end
  ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'spec', 'rails3')
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))
end

FileList['dev_tasks/*.rake', 'lib/sunspot/rails/tasks.rb'].each { |file| load(file) }
