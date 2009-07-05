namespace :schema do
  desc 'Compile schema from Haml template'
  task :compile do
    types = {
      'string' => 'StrField',
      'boolean' => 'BoolField',
      'sint' => 'SortableIntField',
      'sfloat' => 'SortableFloatField',
      'date' => 'DateField'
    }
    fields = {
      's' => 'string',
      'i' => 'sint',
      'f' => 'sfloat',
      'd' => 'date',
      'b' => 'boolean'
    }
    require 'haml'
    template = File.read(
      File.join(File.dirname(__FILE__), '..', 'templates', 'schema.xml.haml')
    )
    engine = Haml::Engine.new(template)
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
      file << engine.render(Object.new, :types => types, :fields => fields)
    end
  end
end
