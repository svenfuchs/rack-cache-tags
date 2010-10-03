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
            urls_by_tags(tags).tap { |urls| Tagging.where(:url => urls).delete_all }
          end

          def urls_by_tags(tags)
            taggings_by_tags(tags).map(&:url)
          end

          def taggings_by_tags(tags)
            sql = "tag IN (?) #{[' OR tag LIKE ?'] * tags.size}"
            Tagging.where(sql, tags, *tags.map { |tag| "#{tag.split(':').first}%" })
          end
        end
      end
    end
  end
end
