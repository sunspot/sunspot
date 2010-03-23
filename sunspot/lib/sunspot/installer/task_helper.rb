module Sunspot
  class Installer
    module TaskHelper
      def say(message)
        if @verbose
          STDOUT.puts(message)
        end
      end

      def add_element(node, name, attributes = {})
        new_node = Nokogiri::XML::Node.new(name, @document)
        attributes.each_pair { |name, value| new_node[name.to_s] = value }
        node << new_node 
        new_node
      end
    end
  end
end
