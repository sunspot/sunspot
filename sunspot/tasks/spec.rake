require 'spec/rake/spectask'

namespace :spec do
  desc 'Run API specs'
  Spec::Rake::SpecTask.new(:api) do |t|
    t.spec_files = FileList['spec/api/**/*_spec.rb']
  end

  desc 'Run integration specs'
  task :integration => 'spec:solr:start' do
    begin
      Rake::Task['spec:integration_runner'].invoke
    ensure
      Rake::Task['spec:solr:stop'].invoke
    end
  end

  Spec::Rake::SpecTask.new(:integration_runner) do |t|
    t.spec_files = FileList['spec/integration/**/*_spec.rb']
  end

  namespace :solr do
    desc 'Start a Solr instance for testing'
    task :start => :calculate_path do
      sh "#{@sunspot_solr} start"
      sleep 5
    end

    desc 'Stop a Solr instance started with spec:solr:start'
    task :stop => :calculate_path do
      sh "#{@sunspot_solr} stop"
    end

    task :calculate_path do
      @sunspot_solr = File.expand_path(File.join(File.dirname(__FILE__), %w(.. bin sunspot-solr)))
    end
  end
end
