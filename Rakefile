require 'rake/clean'
require 'rake/file_list'

TO_CLEAN = Rake::FileList.new do |fl|
  fl.include 'sunspot_rails/tmp/**/*', 'sunspot/vendor/**/*'
  fl.include '**/.bundle'
  fl.exclude 'sunspot_rails/tmp/.gitkeep'
end

CLEAN.include TO_CLEAN

desc 'Release Sunspot, Sunspot::Rails and Sunspot::Solr to Rubygems.org'
task :release do
  FileUtils.cp('README.md', 'sunspot/')

  require File.expand_path('../sunspot/lib/sunspot/version', __FILE__)

  version_tag = "v#{Sunspot::VERSION}"
  system "git tag -am 'Release version #{Sunspot::VERSION}' '#{version_tag}'"
  system "git push origin #{version_tag}:#{version_tag}"

  FileUtils.cd 'sunspot' do
    system "gem build sunspot.gemspec"
    system "gem push sunspot-#{Sunspot::VERSION}.gem"
    FileUtils.rm "sunspot-#{Sunspot::VERSION}.gem"
  end

  FileUtils.cd 'sunspot_rails' do
    system "gem build sunspot_rails.gemspec"
    system "gem push sunspot_rails-#{Sunspot::VERSION}.gem"
    FileUtils.rm("sunspot_rails-#{Sunspot::VERSION}.gem")
  end

  FileUtils.cd 'sunspot_solr' do
    system "gem build sunspot_solr.gemspec"
    system "gem push sunspot_solr-#{Sunspot::VERSION}.gem"
    FileUtils.rm("sunspot_solr-#{Sunspot::VERSION}.gem")
  end
end

desc 'Install bleeding edge gems locally'
task :install do
  %w[sunspot sunspot_rails sunspot_solr].each do |folder|
    FileUtils.cd folder do
      system "rm *.gem"
      system "gem build *.gemspec"
      system "gem install *.gem"
    end
  end
end

desc 'Run all the tests'
task :default do
  exit system([ "GEM=sunspot ci/travis.sh",
                "GEM=sunspot_rails RAILS=3.0.0 ci/travis.sh",
                "GEM=sunspot_rails RAILS=3.1.0 ci/travis.sh",
                "GEM=sunspot_rails RAILS=3.2.0 ci/travis.sh",
                "GEM=sunspot_rails RAILS=4.0.0 ci/travis.sh",
                "GEM=sunspot_rails RAILS=4.1.0 ci/travis.sh",
                "GEM=sunspot_rails RAILS=4.2.0 ci/travis.sh"].join(" && ")) ? 0 : 1
end
