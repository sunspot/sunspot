desc 'Show all TODO and related tags'
task :todo do
  FileList['lib/**/*.rb'].egrep(/#.*(TODO|FIXME|XXX)/)
end
