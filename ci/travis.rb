#!/usr/bin/env ruby

success = false

case ENV['GEM']
when 'sunspot'
  
  Dir.chdir('sunspot') do
    system "bundle install"
    success = system "bundle exec rake spec"
  end

when 'sunspot_rails'
  
  Dir.chdir("sunspot_rails/spec/#{ENV['RAILS']}") do
    system "bundle install"
  end

  Dir.chdir("sunspot_rails") do
    success = system "rake spec:#{ENV['RAILS']}"
  end
  
end

exit(success ? 0 : 1)