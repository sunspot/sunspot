require 'rubygems'
gem 'hpricot'
gem 'syntax'

require 'hpricot'
require 'syntax/convertors/html'

desc 'add syntax highlighting to *.html.source files'
task :syntax do
  Dir.glob('**/*.html.source').each do |filename|
    content = ''
    File.open(filename) do |file|
      content << file.read until file.eof?
    end
    html = Hpricot(content)
    converter = Syntax::Convertors::HTML.for_syntax('ruby')
    html.search('//pre[@class="ruby"]') do |code|
      code.inner_html = converter.convert(code.inner_text, false)
    end
    File.open(filename.sub(/\.source$/, ''), 'w') do |file|
      file.write(html.to_s)
    end
  end
end

task :default => :syntax
