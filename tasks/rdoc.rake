require 'rake/rdoctask'

Rake::RDocTask.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc', 'lib/sunspot.rb', 'lib/sunspot/**/*.rb')
  rdoc.rdoc_dir = 'doc'
end
