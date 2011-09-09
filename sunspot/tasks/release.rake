require File.expand_path('../../lib/sunspot/installer',__FILE__)

desc 'Bundles config files from Sunspot::Solr before release'
task :bundle_solr_config do
  solr_config_dir = File.expand_path('../../../sunspot_solr/solr/solr/conf',__FILE__)
  target_dir = File.expand_path('../../solr_config',__FILE__)
  config_files = Sunspot::Installer::SolrconfigUpdater::CONFIG_FILES + ["schema.xml"]
  config_files.each do |f|
    system %(cp #{File.join(solr_config_dir, f)} #{target_dir})
  end
end