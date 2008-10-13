%w(indexer).each { |filename| require File.join(File.dirname(__FILE__), 'index', filename )}

module Sunspot
  module Index
  end

  class <<Index
    def add(documents)
      ::Sunspot::Index::Indexer.add(documents)
    end
  end
end
