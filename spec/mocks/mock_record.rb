class MockRecord
  IDS = Hash.new { |h, k| h[k] = 0 }
  INSTANCES = Hash.new { |h, k| h[k] = {} }

  attr_reader :id

  def initialize(attrs = {})
    attrs.each_pair do |name, value|
      send(:"#{name}=", value)
    end
    @id = IDS[self.class.name.to_sym] += 1
    INSTANCES[self.class.name.to_sym][@id] = self
  end

  def self.inherited(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def get(id)
      INSTANCES[self.name.to_sym][id]
    end

    def get_all(ids)
      ids.map { |id| get(id) }.sort_by { |instance| instance.id }
    end
  end
end
