# Install bundles for rails2 and rails3 projects
['rails2', 'rails3'].each do |rails|
  Dir.chdir("sunspot_rails/spec/#{rails}") do
    system "bundle install"
  end
end

Dir.chdir("sunspot_rails") do
  system "rake spec:rails2"
  system "rake spec:rails3"
end
