%w(fields scope field_query query restriction search).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
