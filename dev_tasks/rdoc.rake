require 'rake/rdoctask'

Rake::RDocTask.new(:doc) do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc', 'lib/sunspot/rails/**/*.rb')
  rdoc.rdoc_dir = 'doc'
end
