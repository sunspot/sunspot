%w(fields scope field_query query restriction).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
