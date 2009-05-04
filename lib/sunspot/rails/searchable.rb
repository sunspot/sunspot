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

        def searchable?
          false
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

        def reindex(batch = nil)
          remove_all_from_index
          unless batch
            Sunspot.index(all)
          else
            offset = 0
            while(offset < count)
              Sunspot.index(all(:offset => offset, :limit => batch))
              offset += batch
            end
          end
        end

        def index_orphans
          indexed_ids = search_ids.to_set
          all(:select => 'id').each do |object|
            indexed_ids.delete(object.id)
          end
          indexed_ids.to_a
        end

        def clean_index_orphans
          index_orphans.each do |id|
            new do |fake_instance|
              fake_instance.id = id
            end.remove_from_index
          end
        end

        def searchable?
          true
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
