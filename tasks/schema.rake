namespace :schema do
  desc 'Compile schema from Haml template'
  task :compile do
    require File.join(File.dirname(__FILE__), '..', 'lib', 'sunspot', 'schema')
    File.open(
      File.join(
        File.dirname(__FILE__),
        '..',
        'solr',
        'solr',
        'conf',
        'schema.xml'
    ),
      'w'
    ) do |file|
      file << Sunspot::Schema.new.to_xml
    end
  end
end
