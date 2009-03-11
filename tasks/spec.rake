gem 'rspec', '~>1.1'

require 'spec'
require 'spec/rake/spectask'

desc 'run specs'
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList[File.join(File.dirname(__FILE__), '..', 'spec', '**', '*_spec.rb')]
  t.spec_opts = ['--color']
end

namespace :spec do
  desc 'run api specs (mock out Solr dependency)'
  Spec::Rake::SpecTask.new('api') do |t|
    t.spec_files = FileList[File.join(File.dirname(__FILE__), '..', 'spec', 'api', '*_spec.rb')]
    t.spec_opts = ['--color']
  end

  desc 'run integration specs (be sure to run `bin/sunspot-solr start`)'
  Spec::Rake::SpecTask.new('integration') do |t|
    t.spec_files = FileList[File.join(File.dirname(__FILE__), '..', 'spec', 'integration', '*_spec.rb')]
    t.spec_opts = ['--color']
  end
end
