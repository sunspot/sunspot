module Sunspot
  module Rails
    module Searchable
      class <<self
        def included(base)
          base.module_eval { extend(ActsAsMethods) }
        end
      end

      module ActsAsMethods
        def searchable(&block)
          extend ClassMethods
          include InstanceMethods

          Sunspot.setup(self, &block)
        end
      end

      module ClassMethods
        def search(&block)
          Sunspot.search(self, &block)
        end

        def search_ids(&block)
          search(&block).raw_results.map { |raw_result| raw_result.primary_key.to_i }
        end

        def remove_all_from_index
          Sunspot.remove_all(self)
        end

        # XXX Sunspot should implement remove_all!()
        def remove_all_from_index!
          Sunspot.remove_all(self)
          Sunspot.commit
        end
      end

      module InstanceMethods
        def index
          Sunspot.index(self)
        end

        def index!
          Sunspot.index!(self)
        end
        
        def remove_from_index
          Sunspot.remove(self)
        end

        #FIXME Sunspot should implement remove!()
        def remove_from_index!
          Sunspot.remove(self)
          Sunspot.commit
        end
      end
    end
  end
end
