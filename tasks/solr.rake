namespace :solr do
  namespace :test do
    desc 'Start Solr server'
    task :start do
      FileUtils.cd File.join(File.dirname(__FILE__), '..', 'solr') do
        Kernel.fork do
          Kernel.exec("java -jar start.jar 2> #{File.join('..', 'log', 'test_solr.log')}")
        end
      end
    end
  end
end
