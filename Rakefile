desc 'Release Sunspot and Sunspot::Rails to Gemcutter'
task :release do
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
end
