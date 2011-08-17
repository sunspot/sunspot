Dir.chdir('sunspot') do
  system "bundle install"
  system "bundle exec sunspot-solr start"
end