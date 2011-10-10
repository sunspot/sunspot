module Sunspot
  module Solr
    class Railtie < ::Rails::Railtie
	    
      rake_tasks do
        load 'sunspot/solr/tasks.rb'
      end
      
      # generators do
      #   load "generators/sunspot_rails.rb"
      # end

    end
  end
end
