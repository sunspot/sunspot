%w(fields query scope).each do |file|
  require File.join(File.dirname(__FILE__), 'dsl', file)
end
