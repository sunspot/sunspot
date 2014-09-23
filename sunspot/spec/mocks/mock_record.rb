class MockRecord
  IDS = Hash.new { |h, k| h[k] = 0 }
  QUERY_COUNTS = Hash.new { |h, k| h[k] = 0 }
  INSTANCES = Hash.new { |h, k| h[k] = {} }

  attr_reader :id

  class <<self
    def reset!
      IDS[name.to_sym] = 0
      INSTANCES[name.to_sym] = {}
    end
  end

  def initialize(attrs = {})
    @id = attrs.delete(:id) || IDS[self.class.to_s.to_sym] += 1
    INSTANCES[self.class.to_s.to_sym][@id] = self
    attrs.each_pair do |name, value|
      send(:"#{name}=", value)
    end
  end

  def self.inherited(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def get(id)
      QUERY_COUNTS[self.to_s.to_sym] += 1
      get_instance(id)
    end

    def get_all(ids)
      QUERY_COUNTS[self.to_s.to_sym] += 1
      ids.map { |id| get_instance(id) }.compact.sort_by { |instance| instance.id }
    end

    def query_count
      QUERY_COUNTS[self.to_s.to_sym]
    end

    private

    def get_instance(id)
      INSTANCES[self.to_s.to_sym][id]
    end
  end

  def destroy
    INSTANCES[self.class.to_s.to_sym].delete(@id)
  end
end
