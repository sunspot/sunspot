ENV['RUBYOPT'] = '-W1'

# encoding: UTF-8

require 'spec/rake/spectask'

Dir['tasks/**/*.rake'].each { |t| load t }

desc "Run all examples"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = Dir.glob('spec/**/*_spec.rb')
  t.spec_opts << '--format specdoc'
end

task :default => 'spec'
