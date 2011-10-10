module Sunspot
  module Solr
    class Installer
      module TaskHelper
        def say(message)
          if @verbose
            STDOUT.puts(message)
          end
        end
      end
    end
  end
end
