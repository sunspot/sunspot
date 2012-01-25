namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      case RUBY_PLATFORM
      when /w(in)?32$/, /java$/
        abort("This command is not supported on #{RUBY_PLATFORM}. " +
              "Use rake sunspot:solr:run to run Solr in the foreground.")
      end

      if defined?(Sunspot::Rails::Server)
        Sunspot::Rails::Server.new.start
      else
        Sunspot::Solr::Server.new.start
      end

      puts "Successfully started Solr ..."
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      if defined?(Sunspot::Rails::Server)
        Sunspot::Rails::Server.new.run
      else
        Sunspot::Solr::Server.new.run
      end
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      case RUBY_PLATFORM
      when /w(in)?32$/, /java$/
        abort("This command is not supported on #{RUBY_PLATFORM}. " +
              "Use rake sunspot:solr:run to run Solr in the foreground.")
      end

      if defined?(Sunspot::Rails::Server)
        Sunspot::Rails::Server.new.stop
      else
        Sunspot::Solr::Server.new.stop
      end

      puts "Successfully stopped Solr ..."
    end

    # for backwards compatibility
    task :reindex => :"sunspot:reindex"
  end
end
