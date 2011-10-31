module Sunspot
  class ClassSet
    include Enumerable

    def initialize
      @name_to_klass = {}
    end

    def <<(klass)
      @name_to_klass[klass.name.to_sym] = klass
      self
    end
    alias_method :add, :<<

    def each(&block)
      @name_to_klass.values.each(&block)
    end

    def empty?
      @name_to_klass.empty?
    end
  end
end
