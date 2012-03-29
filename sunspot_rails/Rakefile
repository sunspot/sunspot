require 'rake'

begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
end

if File.exist?(sunspot_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'sunspot', 'lib')))
  STDERR.puts("Using sunspot lib at #{sunspot_lib}")
  $: << sunspot_lib
end

task :environment do
end

FileList['dev_tasks/*.rake', 'lib/sunspot/rails/tasks.rb'].each { |file| load(file) }
