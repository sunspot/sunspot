namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows. Please use rake sunspot:solr:run to run Solr in the foreground.')
      end

      if defined?(Sunspot::Solr::Server)
        Sunspot::Solr::Server.new.start
      else
        abort('sunspot_solr gem required for this command. Add gem "sunspot_solr" to Gemfile')
      end
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      if defined?(Sunspot::Solr::Server)
        Sunspot::Solr::Server.new.run
      else
        abort('sunspot_solr gem required for this command. Add gem "sunspot_solr" to Gemfile')
      end
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows.')
      end

      if defined?(Sunspot::Solr::Server)
        Sunspot::Solr::Server.new.stop
      else
        abort('sunspot_solr gem required for this command. Add gem "sunspot_solr" to Gemfile')
      end
    end

    task :reindex => :"sunspot:reindex"
  end

  desc "Reindex all solr models that are located in your application's models directory."
  # This task depends on the standard Rails file naming \
  # conventions, in that the file name matches the defined class name. \
  # By default the indexing system works in batches of 50 records, you can \
  # set your own value for this by using the batch_size argument. You can \
  # also optionally define a list of models to separated by a forward slash '/'
  # 
  # $ rake sunspot:reindex                # reindex all models
  # $ rake sunspot:reindex[1000]          # reindex in batches of 1000
  # $ rake sunspot:reindex[false]         # reindex without batching
  # $ rake sunspot:reindex[,Post]         # reindex only the Post model
  # $ rake sunspot:reindex[1000,Post]     # reindex only the Post model in
  #                                       # batchs of 1000
  # $ rake sunspot:reindex[,Post+Author]  # reindex Post and Author model
  task :reindex, [:batch_size, :models] => [:environment] do |t, args|
    # Set up general options for reindexing
    reindex_options = { :batch_commit => false }
    
    case args[:batch_size]
    when 'false'
      reindex_options[:batch_size] = nil
    when /^\d+$/ 
      reindex_options[:batch_size] = args[:batch_size].to_i if args[:batch_size].to_i > 0
    end

    # Load all the application's models. Models which invoke 'searchable' will register themselves
    # in Sunspot.searchable.
    Dir.glob(Rails.root.join('app/models/**/*.rb')).each { |path| require path }

    # By default, reindex all searchable models
    sunspot_models = Sunspot.searchable

    # Choose a specific subset of models, if requested
    if args[:models]
      model_names = args[:models].split('+')
      sunspot_models = model_names.map{ |m| m.constantize }
    end
    
    # Set up progress_bar to, ah, report progress
    begin
      require 'progress_bar'
      total_documents = sunspot_models.map { | m | m.count }.sum
      reindex_options[:progress_bar] = ProgressBar.new(total_documents)
    rescue LoadError => e
      $stderr.puts "Skipping progress bar: for progress reporting, add gem 'progress_bar' to your Gemfile"
    rescue Exception => e
      $stderr.puts "Error using progress bar: #{e.message}"
    end
    
    # Finally, invoke the class-level solr_reindex on each model
    sunspot_models.each do |model|
      model.solr_reindex(reindex_options)
    end
  end
  
end
