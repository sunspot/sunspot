module Sunspot
  module Java
    def self.installed?
      `java -version &> /dev/null`
      $?.success?
    end
  end
end
