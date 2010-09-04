require 'active_record'

module Rack
  module Cache
    class Tags
      module Store
        class ActiveRecord
          class Tagging < ::ActiveRecord::Base
            set_table_name 'cache_taggings'
          end

          def store(url, tags)
            tags.each { |tag| Tagging.find_or_create_by_url_and_tag(url, tag) }
          end
          
          def purge(tags)
            tags = Tagging.where(:tag => tags)
            urls = tags.map(&:url)
            Tagging.where(:url => urls).delete_all
            urls
          end
        end
      end
    end
  end
end