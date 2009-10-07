gem 'mislav-hanna'
require 'yard'
require 'yard/rake/yardoc_task'
require 'jeweler'

YARD::Rake::YardocTask.new(:doc) do |doc|
  version = Jeweler::VersionHelper.new(File.join(File.dirname(__FILE__), '..')).to_s
  doc.files = ['README.rdoc', 'lib/sunspot.rb', 'lib/sunspot/**/*.rb']
  doc.options = [
    '--readme', 'README.rdoc',
    '--title', "Sunspot #{version} - Solr-powered search for Ruby objects - API Documentation"]
end

namespace :doc do
  desc 'Generate rdoc and move into pages directory'
  task :publish => :redoc do
    doc_dir = File.join(File.dirname(__FILE__), '..', 'doc')
    publish_dir = File.join(File.dirname(__FILE__), '..', 'pages', 'docs')
    FileUtils.rm_rf(publish_dir) if File.exist?(publish_dir)
    FileUtils.cp_r(doc_dir, publish_dir)
  end
end
