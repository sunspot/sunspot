namespace :sunspot do
  namespace :solr do
    
    desc 'Start the Solr instance'
    task :start => :environment do
      case RUBY_PLATFORM
      when /w(in)?32$/, /java$/
        abort("This command is not supported on #{RUBY_PLATFORM}. " +
              "Use rake sunspot:solr:run to run Solr in the foreground.")
      end
      Sunspot::Rails::Server.new.start

      puts "Successfully started Solr ..."
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      Sunspot::Rails::Server.new.run
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      case RUBY_PLATFORM
      when /w(in)?32$/, /java$/
        abort("This command is not supported on #{RUBY_PLATFORM}. " +
              "Use rake sunspot:solr:run to run Solr in the foreground.")
      end
      Sunspot::Rails::Server.new.stop

      puts "Successfully stopped Solr ..."
    end

    # for backwards compatibility
    task :reindex => :"sunspot:reindex"
  end
end
