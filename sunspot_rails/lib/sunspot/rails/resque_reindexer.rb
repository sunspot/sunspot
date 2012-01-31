module Sunspot #:nodoc:
  module Rails #:nodoc:
    class ResqueReindexer
      @queue = :high

      def self.perform(klass, start_id, end_id)
        model = klass.constantize
        records = model.find(:all, :conditions => ["id between ? and ?", start_id, end_id])
        Sunspot.index(records)
      end
    end
  end
end