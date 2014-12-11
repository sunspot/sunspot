rdoc_task =
  begin
    require 'rdoc/task'
    RDoc::Task
  rescue LoadError
    begin
      require 'rake/rdoctask'
      Rake::RDocTask
    rescue
      nil
    end
  end

if rdoc_task
  rdoc_task.new(:doc) do |rdoc|
    rdoc.main = '../README.md'
    rdoc.rdoc_files.include('../README.md', 'lib/sunspot/rails/**/*.rb', 'lib/sunspot/rails.rb')
    rdoc.rdoc_dir = 'doc'
  end
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
