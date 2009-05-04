require 'escape'

namespace :sunspot do
  namespace :solr do
    desc 'Start the Solr instance'
    task :start => :environment do
      path = File.join(::Rails.root, 'solr', 'data', ::Rails.env)
      FileUtils.mkdir_p(path)
      port = Sunspot::Rails.configuration.port
      system(Escape.shell_command(['sunspot-solr', 'start', '--', '-p', port.to_s, '-d', path]))
    end

    desc 'Stop the Solr instance'
    task :stop do
      system(Escape.shell_command(['sunspot-solr', 'stop']))
    end
  end
end
