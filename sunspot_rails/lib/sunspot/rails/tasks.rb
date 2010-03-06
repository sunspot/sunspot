namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows. Please use rake sunspot:solr:run to run Solr in the foreground.')
      end
      Sunspot::Rails::Server.new.start
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      Sunspot::Rails::Server.new.run
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows.')
      end
      Sunspot::Rails::Server.new.stop
    end

    task :reindex => :"sunspot:reindex"
  end

  desc 'Reindex all solr models'
  task :reindex => :environment do
    all_files = Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '*.rb'))
    all_models = all_files.map { |path| File.basename(path, '.rb').camelize.constantize }
    sunspot_models = all_models.select { |m| m < ActiveRecord::Base and m.solr_searchable? }

    sunspot_models.each do |model|
      model.solr_reindex :batch_commit => false
    end
  end
end
