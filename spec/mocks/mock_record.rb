class MockRecord
  IDS = Hash.new do |h, k|
    h[k] ||= 0
  end

  INSTANCES = Hash.new do |h, k|
    h[k] ||= {}
  end

  def initialize(attrs = {})
    attrs.each_pair do |name, value|
      send(:"#{name}=", value)
    end
    @id = IDS[self.class.name.to_sym] += 1
    INSTANCES[self.class.name.to_sym][@id] = self
  end

  def get(id)
    IDS[self.class.name.to_sym][id]
  end

  def get_all(ids)
    ids.map { |id| get(id) }.sort_by { |instance| instance.id }
  end
end
