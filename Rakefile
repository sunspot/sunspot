desc 'Release Sunspot and Sunspot::Rails to Gemcutter'
task :release do
  FileUtils.cp('README.rdoc', 'sunspot/')
  system "git commit sunspot/README.rdoc -qm 'Updating README for gem release'"

  require File.expand_path('../sunspot/lib/sunspot/version', __FILE__)

  version_tag = "v#{Sunspot::VERSION}"
  system "git tag '#{version_tag}' -a 'Release version #{Sunspot::VERSION}'"
  system "git push origin #{version_tag}:#{version_tag}"

  system "gem build sunspot/sunspot.gemspec"
  system "gem build sunspot_rails/sunspot_rails.gemspec"

  system "gem push sunspot-#{Sunspot::VERSION}.gem"
  system "gem push sunspot_rails-#{Sunspot::VERSION}.gem"

  system "rm sunspot-#{Sunspot::VERSION}.gem"
  system "rm sunspot_rails-#{Sunspot::VERSION}.gem"
end
