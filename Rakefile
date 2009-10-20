require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

task :default => :spec

if File.exist?(sunspot_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'sunspot', 'lib')))
  STDERR.puts("Using sunspot lib at #{sunspot_lib}")
  $: << sunspot_lib
end

desc 'Run all specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.spec_opts << '--color'
end

task :environment do
  if ENV['SUNSPOT_LIB']
    $: << ENV['SUNSPOT_LIB']
  end
  ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'spec', 'mock_app')
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))
end

FileList['dev_tasks/*.rake', 'lib/sunspot/rails/tasks.rb'].each { |file| load(file) }
