require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

task :default => :spec

desc 'Run all specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << '--color'
end

desc 'Generate documentation for the sunspot_rails plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SunspotRails'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :environment do
  ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'spec', 'mock_app')
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))
end

FileList['tasks/*.rake'].each { |file| load(file) }
