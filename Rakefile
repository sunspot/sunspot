require 'spec'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList[File.join(File.dirname(__FILE__), 'sunspot', 'spec', 'api')]
end

task :default => :spec
