begin
  require 'hanna/rdoctask'
rescue LoadError
  if require 'rubygems'
    retry
  end
  # It's OK if hanna isn't installed.
end

Rake::RDocTask.new(:doc) do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('README.md', 'lib/sunspot/rails/**/*.rb', 'lib/sunspot/rails.rb')
  rdoc.rdoc_dir = 'doc'
end

namespace :doc do
  desc 'Generate rdoc and move into pages directory'
  task :publish => :redoc do
    doc_dir = File.join(File.dirname(__FILE__), '..', 'doc')
    publish_dir = File.join(File.dirname(__FILE__), '..', '..', 'pages', 'rails', 'docs')
    FileUtils.rm_rf(publish_dir) if File.exist?(publish_dir)
    FileUtils.cp_r(doc_dir, publish_dir)
  end
end
