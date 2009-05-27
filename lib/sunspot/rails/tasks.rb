require 'escape'

namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      data_path = File.join(::Rails.root, 'solr', 'data', ::Rails.env)
      pid_path = File.join(::Rails.root, 'solr', 'pids', ::Rails.env)
      [data_path, pid_path].each { |path| FileUtils.mkdir_p(path) }
      port = Sunspot::Rails.configuration.port
      FileUtils.cd(File.join(pid_path)) do
        system(Escape.shell_command(['sunspot-solr', 'start', '--', '-p', port.to_s, '-d', data_path]))
      end
    end

    desc 'Stop the Solr instance'
    task :stop => :environment do
      FileUtils.cd(File.join(::Rails.root, 'solr', 'pids', ::Rails.env)) do
        system(Escape.shell_command(['sunspot-solr', 'stop']))
      end
    end
  end
end
