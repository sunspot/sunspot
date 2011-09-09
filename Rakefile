load File.expand_path('../sunspot/tasks/release.rake', __FILE__)

desc 'Release Sunspot, Sunspot::Rails and Sunspot::Solr to Gemcutter'
task :release => :bundle_solr_config  do
  FileUtils.cp('README.rdoc', 'sunspot/')

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


desc 'Run all the tests'
task :default do
  exit system([ "GEM=sunspot ci/travis.sh",
                "GEM=sunspot_rails RAILS=rails2 ci/travis.sh",
                "GEM=sunspot_rails RAILS=rails3 ci/travis.sh" ].join(" && ")) ? 0 : 1
end
