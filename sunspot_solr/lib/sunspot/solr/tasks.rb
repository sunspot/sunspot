namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task start: :environment do
      server.start
      puts 'Successfully started Solr ...'
    end

    desc 'Run the Solr instance in the foreground'
    task run: :environment do
      server.run
    end

    desc 'Stop the Solr instance'
    task stop: :environment do
      server.stop
      puts 'Successfully stopped Solr ...'
    end

    desc 'Restart the Solr instance'
    task restart: :environment do
      Rake::Task['sunspot:solr:stop'].invoke if File.exist?(server.pid_path)
      Rake::Task['sunspot:solr:start'].invoke
    end

    # for backwards compatibility
    task reindex: :"sunspot:reindex"

    def server
      if defined?(Sunspot::Rails::Server)
        Sunspot::Rails::Server.new
      else
        Sunspot::Solr::Server.new
      end
    end
  end
end
