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

  desc "Reindex all solr models that are located in your application's models directory."
  # This task depends on the standard Rails file naming \
  # conventions, in that the file name matches the defined class name. \
  # By default the indexing system works in batches of 500 records, you can \
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
  task :reindex, :batch_size, :models, :needs => :environment do |t, args|
    reindex_options = {:batch_commit => false}
    case args[:batch_size]
    when 'false'
      reindex_options[:batch_size] = nil
    when /^\d+$/ 
      reindex_options[:batch_size] = args[:batch_size].to_i if args[:batch_size].to_i > 0
    end
    unless args[:models]
      all_files = Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '*.rb'))
      all_models = all_files.map { |path| File.basename(path, '.rb').camelize.constantize }
      sunspot_models = all_models.select { |m| m < ActiveRecord::Base and m.searchable? }
    else
      sunspot_models = args[:models].split('+').map{|m| m.constantize}
    end
    raise reindex_options.inspect
    sunspot_models.each do |model|
      model.solr_reindex reindex_options
    end
  end
  
end
