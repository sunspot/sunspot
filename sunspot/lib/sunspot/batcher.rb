module Sunspot
  #
  # Keeps a stack of batches and helps out when Indexer is asked to batch documents.
  #
  # If the client does something like 
  #   
  #   Sunspot.batch do
  #     some_code_here
  #     which_triggers_some_other_code
  #     which_again_calls
  #     Sunspot.batch { ... }
  #   end
  #
  # it is the Batcher's job to keep track of these nestings. The inner will
  # be sent of to be indexed first.
  #
  class Batcher
    include Enumerable

    # Raised if you ask to end current, but no current exists
    class NoCurrentBatchError < StandardError; end

    def initialize
      @stack = []
    end

    def current
      @stack.last or start_new
    end

    def start_new
      (@stack << []).last
    end

    def end_current
      fail NoCurrentBatchError if @stack.empty?

      @stack.pop
    end

    def depth
      @stack.length
    end

    def batching?
      depth > 0
    end

    def each(&block)
      current.each(&block)
    end

    def push(value)
      current << value
    end
    alias << push

    def concat(values)
      current.concat values
    end
  end
end
