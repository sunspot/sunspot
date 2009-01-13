require 'rake'
require 'spec/rake/spectask'

desc 'run specs with rcov'
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_dir = File.join('coverage', 'all')
  t.rcov_opts.concat(['--exclude', 'spec', '--sort', 'coverage', '--only-uncovered'])
end

namespace :rcov do
  desc 'run api specs with rcov'
  Spec::Rake::SpecTask.new('api') do |t|
    t.spec_files = FileList['spec/api/*_spec.rb']
    t.rcov = true
    t.rcov_dir = File.join('coverage', 'api')
    t.rcov_opts.concat(['--exclude', 'spec', '--sort', 'coverage', '--only-uncovered'])
  end

  desc 'run integration specs with rcov'
  Spec::Rake::SpecTask.new('integration') do |t|
    t.spec_files = FileList['spec/integration/*_spec.rb']
    t.rcov = true
    t.rcov_dir = File.join('coverage', 'integration')
    t.rcov_opts.concat(['--exclude', 'spec', '--sort', 'coverage', '--only-uncovered'])
  end
end
