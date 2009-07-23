require 'escape'

namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      if RUBY_PLATFORM =~ /w(in)?32$/
        abort('This command does not work on Windows. Please use rake sunspot:solr:run to run Solr in the foreground.')
      end
      data_path = File.join(::Rails.root, 'solr', 'data', ::Rails.env)
      pid_path = File.join(::Rails.root, 'solr', 'pids', ::Rails.env)
      solr_home =
        if %w(solrconfig schema).all? { |file| File.exist?(File.join(::Rails.root, 'solr', 'conf', "#{file}.xml")) }
          File.join(::Rails.root, 'solr')
        end
      [data_path, pid_path].each { |path| FileUtils.mkdir_p(path) }
      port = Sunspot::Rails.configuration.port
      FileUtils.cd(File.join(pid_path)) do
        command = ['sunspot-solr', 'start', '--', '-p', port.to_s, '-d', data_path]
        if solr_home
          command << '-s' << solr_home
        end
        system(Escape.shell_command(command))
      end
    end

    desc 'Run the Solr instance in the foreground'
    task :run => :environment do
      data_path = File.join(::Rails.root, 'solr', 'data', ::Rails.env)
      solr_home =
        if %w(solrconfig schema).all? { |file| File.exist?(File.join(::Rails.root, 'solr', 'conf', "#{file}.xml")) }
          File.join(::Rails.root, 'solr')
        end
      FileUtils.mkdir_p(data_path)
      port = Sunspot::Rails.configuration.port
      command = ['sunspot-solr', 'run', '--', '-p', port.to_s, '-d', data_path]
      if RUBY_PLATFORM =~ /w(in)?32$/
        command.first << '.bat'
      end
      if solr_home
        command << '-s' << solr_home
      end
      exec(Escape.shell_command(command))
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      FileUtils.cd(File.join(::Rails.root, 'solr', 'pids', ::Rails.env)) do
        system(Escape.shell_command(['sunspot-solr', 'stop']))
      end
    end
  end
end
