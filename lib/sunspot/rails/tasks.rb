namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows. Please use rake sunspot:solr:run to run Solr in the foreground.')
      end
      Sunspot::Rails::Server.start
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      Sunspot::Rails::Server.run
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows.')
      end
      Sunspot::Rails::Server.stop
    end
  end
end
