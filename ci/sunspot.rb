Dir.chdir('sunspot') do
  system "bundle install"
  system "bundle exec rake spec"
end  

